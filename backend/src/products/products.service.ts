import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from './product.entity';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { MAX_PRODUCT_IMAGES } from '../cloudinary/image-file.filter';

/** Files from the multipart form, grouped by field name. */
export interface ProductImageFiles {
  images?: Express.Multer.File[];
  /** Single photo sent by older app versions; replaces all existing photos. */
  image?: Express.Multer.File[];
}

@Injectable()
export class ProductsService {
  private readonly logger = new Logger(ProductsService.name);

  constructor(
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    private readonly cloudinary: CloudinaryService,
  ) {}

  async create(
    dto: CreateProductDto,
    files?: ProductImageFiles,
  ): Promise<Product> {
    const newFiles = [...(files?.images ?? []), ...(files?.image ?? [])];
    this.checkImageCount(newFiles.length);
    const imageUrls = await this.uploadAll(newFiles);
    try {
      return await this.productRepo.save(
        this.productRepo.create({
          ...dto,
          imageUrls,
          imageUrl: imageUrls[0] ?? null,
        }),
      );
    } catch (err) {
      await this.safeDeleteImages(imageUrls);
      throw err;
    }
  }

  findAll(): Promise<Product[]> {
    return this.productRepo.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: number): Promise<Product> {
    const product = await this.productRepo.findOne({ where: { id } });
    if (!product) throw new NotFoundException(`Product #${id} not found`);
    return product;
  }

  findByCategory(category: string): Promise<Product[]> {
    return this.productRepo.find({
      where: { category },
      order: { createdAt: 'DESC' },
    });
  }

  search(q: string): Promise<Product[]> {
    const term = `%${q.trim().toLowerCase()}%`;
    return this.productRepo
      .createQueryBuilder('product')
      .where('LOWER(product.name) LIKE :term', { term })
      .orWhere('LOWER(product.category) LIKE :term', { term })
      .orWhere('LOWER(product.description) LIKE :term', { term })
      .orderBy('product.createdAt', 'DESC')
      .take(50)
      .getMany();
  }

  /**
   * Updates fields and photos. New photos in "images" are added after the
   * existing ones; URLs in removeImageUrls are deleted. A photo in the
   * legacy "image" field replaces all existing photos.
   */
  async update(
    id: number,
    dto: UpdateProductDto,
    files?: ProductImageFiles,
  ): Promise<Product> {
    const { removeImageUrls = [], ...fields } = dto;
    const product = await this.findOne(id);
    const current = this.imagesOf(product);

    const legacy = files?.image ?? [];
    const removed = legacy.length
      ? current
      : current.filter((url) => removeImageUrls.includes(url));
    const kept = current.filter((url) => !removed.includes(url));
    const newFiles = [...legacy, ...(files?.images ?? [])];
    this.checkImageCount(kept.length + newFiles.length);

    const added = await this.uploadAll(newFiles);
    product.imageUrls = [...kept, ...added];
    product.imageUrl = product.imageUrls[0] ?? null;
    Object.assign(product, fields);
    let saved: Product;
    try {
      saved = await this.productRepo.save(product);
    } catch (err) {
      await this.safeDeleteImages(added);
      throw err;
    }
    await this.safeDeleteImages(removed);
    return saved;
  }

  async remove(id: number): Promise<{ message: string }> {
    const product = await this.findOne(id);
    const images = this.imagesOf(product);
    await this.productRepo.remove(product);
    await this.safeDeleteImages(images);
    return { message: `Product #${id} deleted successfully` };
  }

  /** Products saved before the gallery existed may only have imageUrl. */
  private imagesOf(product: Product): string[] {
    if (product.imageUrls?.length) return product.imageUrls;
    return product.imageUrl ? [product.imageUrl] : [];
  }

  private checkImageCount(count: number) {
    if (count > MAX_PRODUCT_IMAGES) {
      throw new BadRequestException(
        `A product can have at most ${MAX_PRODUCT_IMAGES} photos`,
      );
    }
  }

  /** Uploads in parallel; if any upload fails, the others are cleaned up. */
  private async uploadAll(files: Express.Multer.File[]): Promise<string[]> {
    const results = await Promise.allSettled(
      files.map((file) => this.cloudinary.uploadImage(file)),
    );
    const urls = results
      .filter((r) => r.status === 'fulfilled')
      .map((r) => r.value);
    const failed = results.find((r) => r.status === 'rejected');
    if (failed) {
      await this.safeDeleteImages(urls);
      throw failed.reason;
    }
    return urls;
  }

  /** A failed image cleanup must not fail the user's request. */
  private async safeDeleteImages(urls: string[]) {
    await Promise.all(
      urls.map(async (url) => {
        try {
          await this.cloudinary.deleteImage(url);
        } catch (err) {
          this.logger.warn(
            `Could not delete image ${url}: ${(err as Error).message}`,
          );
        }
      }),
    );
  }
}
