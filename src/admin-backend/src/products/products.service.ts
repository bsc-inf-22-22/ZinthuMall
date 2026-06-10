import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from './products.entity';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

@Injectable()
export class ProductsService {
  constructor(
    @InjectRepository(Product)
    private productRepo: Repository<Product>,
    private cloudinaryService: CloudinaryService,
  ) {}

  async create(dto: CreateProductDto, file?: Express.Multer.File): Promise<Product> {
    let imageUrl: string | undefined;

    if (file) {
      imageUrl = await this.cloudinaryService.uploadImage(file);
    }

    const product = this.productRepo.create({ ...dto, imageUrl });
    return this.productRepo.save(product);
  }

  async findAll(): Promise<Product[]> {
    return this.productRepo.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: number): Promise<Product> {
    const product = await this.productRepo.findOne({ where: { id } });
    if (!product) throw new NotFoundException(`Product #${id} not found`);
    return product;
  }

  async update(id: number, dto: UpdateProductDto, file?: Express.Multer.File): Promise<Product> {
    const product = await this.findOne(id);

    if (file) {
      if (product.imageUrl) {
        await this.cloudinaryService.deleteImage(product.imageUrl);
      }
      product.imageUrl = await this.cloudinaryService.uploadImage(file);
    }

    Object.assign(product, dto);
    return this.productRepo.save(product);
  }

  async remove(id: number): Promise<{ message: string }> {
    const product = await this.findOne(id);

    if (product.imageUrl) {
      await this.cloudinaryService.deleteImage(product.imageUrl);
    }

    await this.productRepo.remove(product);
    return { message: `Product #${id} deleted successfully` };
  }
}