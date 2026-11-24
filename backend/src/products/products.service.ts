import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from './product.entity';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

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
    file?: Express.Multer.File,
  ): Promise<Product> {
    const imageUrl = file ? await this.cloudinary.uploadImage(file) : null;
    return this.productRepo.save(this.productRepo.create({ ...dto, imageUrl }));
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

  async update(
    id: number,
    dto: UpdateProductDto,
    file?: Express.Multer.File,
  ): Promise<Product> {
    const product = await this.findOne(id);
    if (file) {
      const oldUrl = product.imageUrl;
      product.imageUrl = await this.cloudinary.uploadImage(file);
      if (oldUrl) await this.safeDeleteImage(oldUrl);
    }
    Object.assign(product, dto);
    return this.productRepo.save(product);
  }

  async remove(id: number): Promise<{ message: string }> {
    const product = await this.findOne(id);
    await this.productRepo.remove(product);
    if (product.imageUrl) await this.safeDeleteImage(product.imageUrl);
    return { message: `Product #${id} deleted successfully` };
  }

  /** A failed image cleanup must not fail the user's request. */
  private async safeDeleteImage(url: string) {
    try {
      await this.cloudinary.deleteImage(url);
    } catch (err) {
      this.logger.warn(
        `Could not delete image ${url}: ${(err as Error).message}`,
      );
    }
  }
}
