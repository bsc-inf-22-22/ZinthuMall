import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WishlistItem } from './wishlist-item.entity';
import { Product } from '../products/product.entity';

@Injectable()
export class WishlistService {
  constructor(
    @InjectRepository(WishlistItem)
    private readonly repo: Repository<WishlistItem>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
  ) {}

  /** Returns the customer's saved products, newest first. */
  async list(customerId: number): Promise<Product[]> {
    const items = await this.repo.find({
      where: { customerId },
      order: { createdAt: 'DESC' },
    });
    return items.map((i) => i.product);
  }

  async add(
    customerId: number,
    productId: number,
  ): Promise<{ message: string }> {
    if (!(await this.productRepo.exists({ where: { id: productId } }))) {
      throw new NotFoundException(`Product #${productId} not found`);
    }
    await this.repo
      .createQueryBuilder()
      .insert()
      .values({ customerId, productId })
      .orIgnore()
      .execute();
    return { message: 'Added to wishlist' };
  }

  async remove(
    customerId: number,
    productId: number,
  ): Promise<{ message: string }> {
    await this.repo.delete({ customerId, productId });
    return { message: 'Removed from wishlist' };
  }
}
