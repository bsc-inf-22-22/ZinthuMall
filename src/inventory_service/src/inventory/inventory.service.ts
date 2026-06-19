import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AddStockDto } from './dto/add-stock.dto';
import { ReduceStockDto } from './dto/reduce-stock.dto';

@Injectable()
export class InventoryService {
  constructor(private prismaService: PrismaService) {}

  async getAllInventory() {
    return this.prismaService.prisma.product.findMany();
  }

  async getLowStockProducts() {
    return this.prismaService.prisma.product.findMany({
      where: { quantityInStock: { lt: 5 } },
    });
  }

  async getOutOfStockProducts() {
    return this.prismaService.prisma.product.findMany({
      where: { quantityInStock: 0 },
    });
  }

  async addStock(dto: AddStockDto) {
    const product = await this.prismaService.prisma.product.findUnique({
      where: { id: dto.productId },
    });

    if (!product) throw new NotFoundException('Product not found');

    const newQty = product.quantityInStock + dto.quantity;
    const status = newQty === 0 ? 'OUT_OF_STOCK' : newQty < 5 ? 'LOW_STOCK' : 'IN_STOCK';

    const updated = await this.prismaService.prisma.product.update({
      where: { id: dto.productId },
      data: { quantityInStock: newQty, status },
    });

    await this.prismaService.prisma.inventoryTransaction.create({
      data: {
        productId: dto.productId,
        quantity: dto.quantity,
        transactionType: 'STOCK_IN',
        notes: dto.notes || `Added ${dto.quantity} units`,
      },
    });

    return { message: 'Stock added successfully', product: updated };
  }

  async reduceStock(dto: ReduceStockDto) {
    const product = await this.prismaService.prisma.product.findUnique({
      where: { id: dto.productId },
    });

    if (!product) throw new NotFoundException('Product not found');
    if (product.quantityInStock < dto.quantity) throw new BadRequestException('Insufficient stock');

    const newQty = product.quantityInStock - dto.quantity;
    const status = newQty === 0 ? 'OUT_OF_STOCK' : newQty < 5 ? 'LOW_STOCK' : 'IN_STOCK';

    const updated = await this.prismaService.prisma.product.update({
      where: { id: dto.productId },
      data: { quantityInStock: newQty, status },
    });

    await this.prismaService.prisma.inventoryTransaction.create({
      data: {
        productId: dto.productId,
        quantity: dto.quantity,
        transactionType: dto.notes?.includes('SALE') ? 'SALE' : 'STOCK_OUT',
        notes: dto.notes || `Reduced ${dto.quantity} units`,
      },
    });

    return { message: 'Stock reduced successfully', product: updated };
  }

  async getTransactionHistory(productId: number) {
    const product = await this.prismaService.prisma.product.findUnique({
      where: { id: productId },
    });
    if (!product) throw new NotFoundException('Product not found');

    const transactions = await this.prismaService.prisma.inventoryTransaction.findMany({
      where: { productId },
      orderBy: { transactionDate: 'desc' },
    });

    return { product, transactions };
  }
}