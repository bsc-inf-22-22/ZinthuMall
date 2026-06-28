import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OrderView } from './orders-view.entity';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';

@Injectable()
export class OrdersViewService {
  constructor(
    @InjectRepository(OrderView)
    private orderRepo: Repository<OrderView>,
  ) {}

  async findAll(): Promise<OrderView[]> {
    return this.orderRepo.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: number): Promise<OrderView> {
    const order = await this.orderRepo.findOne({ where: { id } });
    if (!order) throw new NotFoundException(`Order #${id} not found`);
    return order;
  }

  async updateStatus(id: number, dto: UpdateOrderStatusDto): Promise<OrderView> {
    const order = await this.findOne(id);
    order.status = dto.status;
    return this.orderRepo.save(order);
  }

  async getOrdersByStatus(status: string): Promise<OrderView[]> {
    return this.orderRepo.find({
      where: { status },
      order: { createdAt: 'DESC' },
    });
  }

  async getOrderStats() {
    const total = await this.orderRepo.count();
    const pending = await this.orderRepo.count({ where: { status: 'pending' } });
    const processing = await this.orderRepo.count({ where: { status: 'processing' } });
    const shipped = await this.orderRepo.count({ where: { status: 'shipped' } });
    const delivered = await this.orderRepo.count({ where: { status: 'delivered' } });

    const revenue = await this.orderRepo
      .createQueryBuilder('order')
      .select('SUM(order.totalAmount)', 'total')
      .where('order.paymentStatus = :status', { status: 'paid' })
      .getRawOne();

    return {
      total,
      pending,
      processing,
      shipped,
      delivered,
      totalRevenue: revenue.total || 0,
    };
  }
}