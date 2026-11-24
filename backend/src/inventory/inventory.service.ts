import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { Between, DataSource, EntityManager } from 'typeorm';
import { Product } from '../products/product.entity';
import {
  InventoryTransaction,
  InventoryTransactionType,
} from './inventory-transaction.entity';
import { AdjustStockDto } from './dto/adjust-stock.dto';

export const LOW_STOCK_THRESHOLD = 5;

export function stockStatus(
  stock: number,
): 'OUT_OF_STOCK' | 'LOW_STOCK' | 'IN_STOCK' {
  if (stock <= 0) return 'OUT_OF_STOCK';
  if (stock < LOW_STOCK_THRESHOLD) return 'LOW_STOCK';
  return 'IN_STOCK';
}

@Injectable()
export class InventoryService {
  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  async getAll() {
    const products = await this.dataSource
      .getRepository(Product)
      .find({ order: { name: 'ASC' } });
    return products.map((p) => this.toStockView(p));
  }

  async getLowStock() {
    const products = await this.dataSource.getRepository(Product).find({
      where: { stock: Between(1, LOW_STOCK_THRESHOLD - 1) },
      order: { stock: 'ASC' },
    });
    return products.map((p) => this.toStockView(p));
  }

  async getOutOfStock() {
    const products = await this.dataSource
      .getRepository(Product)
      .find({ where: { stock: 0 } });
    return products.map((p) => this.toStockView(p));
  }

  addStock(dto: AdjustStockDto) {
    return this.dataSource.transaction(async (em) => {
      const product = await this.adjust(
        em,
        dto.productId,
        dto.quantity,
        'STOCK_IN',
        dto.notes,
      );
      return {
        message: 'Stock added successfully',
        product: this.toStockView(product),
      };
    });
  }

  reduceStock(dto: AdjustStockDto) {
    return this.dataSource.transaction(async (em) => {
      const product = await this.adjust(
        em,
        dto.productId,
        -dto.quantity,
        'STOCK_OUT',
        dto.notes,
      );
      return {
        message: 'Stock reduced successfully',
        product: this.toStockView(product),
      };
    });
  }

  async getHistory(productId: number) {
    const product = await this.dataSource
      .getRepository(Product)
      .findOne({ where: { id: productId } });
    if (!product) throw new NotFoundException('Product not found');
    const transactions = await this.dataSource
      .getRepository(InventoryTransaction)
      .find({
        where: { productId },
        order: { createdAt: 'DESC' },
      });
    return { product: this.toStockView(product), transactions };
  }

  /**
   * Changes a product's stock inside an existing transaction and logs it.
   * The row is locked so two simultaneous orders can't oversell.
   * Used by the orders module when an order is placed or cancelled.
   */
  async adjust(
    em: EntityManager,
    productId: number,
    delta: number,
    type: InventoryTransactionType,
    notes?: string | null,
  ): Promise<Product> {
    const product = await em.getRepository(Product).findOne({
      where: { id: productId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!product)
      throw new NotFoundException(`Product #${productId} not found`);

    const newStock = product.stock + delta;
    if (newStock < 0) {
      throw new BadRequestException(
        `Not enough stock for "${product.name}" (only ${product.stock} left)`,
      );
    }

    product.stock = newStock;
    await em.getRepository(Product).save(product);
    await em
      .getRepository(InventoryTransaction)
      .save({ productId, quantity: delta, type, notes: notes ?? null });
    return product;
  }

  private toStockView(p: Product) {
    return {
      id: p.id,
      name: p.name,
      category: p.category,
      price: p.price,
      stock: p.stock,
      status: stockStatus(p.stock),
    };
  }
}
