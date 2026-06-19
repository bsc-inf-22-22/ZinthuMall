import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../products/products.entity';
import { OrderView } from '../orders-view/orders-view.entity';

@Injectable()
export class AnalyticsService {
  constructor(
    @InjectRepository(Product)
    private productRepo: Repository<Product>,
    @InjectRepository(OrderView)
    private orderRepo: Repository<OrderView>,
  ) {}

  async getSummary() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    const startOfWeek = new Date(today);
    startOfWeek.setDate(startOfWeek.getDate() - 7);

    const startOfMonth = new Date(today);
    startOfMonth.setDate(1);

    const lastMonth = new Date(startOfMonth);
    lastMonth.setMonth(lastMonth.getMonth() - 1);

    //Total revenue
    const totalRevenueResult = await this.orderRepo
      .createQueryBuilder('order')
      .select('SUM(order.totalAmount)', 'total')
      .where('order.paymentStatus = :status', { status: 'paid' })
      .getRawOne();

    //This month revenue
    const thisMonthRevenue = await this.orderRepo
      .createQueryBuilder('order')
      .select('SUM(order.totalAmount)', 'total')
      .where('order.paymentStatus = :status', { status: 'paid' })
      .andWhere('order.createdAt >= :startOfMonth', { startOfMonth })
      .getRawOne();

    // Last month revenue
    const lastMonthRevenue = await this.orderRepo
      .createQueryBuilder('order')
      .select('SUM(order.totalAmount)', 'total')
      .where('order.paymentStatus = :status', { status: 'paid' })
      .andWhere('order.createdAt >= :lastMonth', { lastMonth })
      .andWhere('order.createdAt < :startOfMonth', { startOfMonth })
      .getRawOne();

    // Revenue growth percentage
    const thisMonth = parseFloat(thisMonthRevenue.total) || 0;
    const lastMonthTotal = parseFloat(lastMonthRevenue.total) || 0;
    const revenueGrowth = lastMonthTotal > 0
      ? Math.round(((thisMonth - lastMonthTotal) / lastMonthTotal) * 100)
      : 0;

    // Orders today
    const ordersToday = await this.orderRepo
      .createQueryBuilder('order')
      .where('order.createdAt >= :today', { today })
      .getCount();

    // Orders yesterday
    const ordersYesterday = await this.orderRepo
      .createQueryBuilder('order')
      .where('order.createdAt >= :yesterday', { yesterday })
      .andWhere('order.createdAt < :today', { today })
      .getCount();

    // Products listed
    const productsListed = await this.productRepo.count();

    // Products added this week
    const productsThisWeek = await this.productRepo
      .createQueryBuilder('product')
      .where('product.createdAt >= :startOfWeek', { startOfWeek })
      .getCount();

    return {
      totalRevenue: parseFloat(totalRevenueResult.total) || 0,
      revenueGrowth,
      ordersToday,
      ordersTodayGrowth: ordersToday - ordersYesterday,
      productsListed,
      productsAddedThisWeek: productsThisWeek,
    };
  }

  async getRevenueChart() {
    const days: { date: string; revenue: number }[] = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      date.setHours(0, 0, 0, 0);

      const nextDate = new Date(date);
      nextDate.setDate(nextDate.getDate() + 1);

      const result = await this.orderRepo
        .createQueryBuilder('order')
        .select('SUM(order.totalAmount)', 'total')
        .where('order.paymentStatus = :status', { status: 'paid' })
        .andWhere('order.createdAt >= :date', { date })
        .andWhere('order.createdAt < :nextDate', { nextDate })
        .getRawOne();

      days.push({
        date: date.toISOString().split('T')[0],
        revenue: parseFloat(result.total) || 0,
      });
    }
    return days;
  }

  async getTopProducts() {
    const orders = await this.orderRepo.find();
    const productMap: Record<number, any> = {};

    for (const order of orders) {
      const items = order.items as any[];
      for (const item of items) {
        if (!productMap[item.productId]) {
          productMap[item.productId] = {
            productId: item.productId,
            productName: item.productName,
            totalSold: 0,
            totalRevenue: 0,
          };
        }
        productMap[item.productId].totalSold += item.quantity;
        productMap[item.productId].totalRevenue += item.price * item.quantity;
      }
    }

    return Object.values(productMap)
      .sort((a, b) => b.totalSold - a.totalSold)
      .slice(0, 5);
  }
}