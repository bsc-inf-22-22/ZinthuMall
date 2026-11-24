import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { DataSource, In, Repository } from 'typeorm';
import { Order, OrderItem } from './order.entity';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { UpdatePaymentDto } from './dto/update-payment.dto';
import { Product } from '../products/product.entity';
import {
  InventoryService,
  LOW_STOCK_THRESHOLD,
} from '../inventory/inventory.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SettingsService } from '../settings/settings.service';

const round2 = (n: number) => Math.round(n * 100) / 100;

/** Compare phone numbers by their last 9 digits (handles 0… vs +265…). */
const samePhone = (a: string, b: string) =>
  a.replace(/\D/g, '').slice(-9) === b.replace(/\D/g, '').slice(-9);

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order) private readonly orderRepo: Repository<Order>,
    @InjectDataSource() private readonly dataSource: DataSource,
    private readonly inventory: InventoryService,
    private readonly notifications: NotificationsService,
    private readonly settings: SettingsService,
  ) {}

  // ── Customer / checkout ───────────────────────────────────────

  async place(dto: CreateOrderDto, customerId?: number): Promise<Order> {
    const settings = await this.settings.get();

    return this.dataSource.transaction(async (em) => {
      const ids = [...new Set(dto.items.map((i) => i.productId))];
      const products = await em.getRepository(Product).findBy({ id: In(ids) });
      const byId = new Map(products.map((p) => [p.id, p]));

      const items: OrderItem[] = [];
      for (const line of dto.items) {
        const product = byId.get(line.productId);
        if (!product)
          throw new BadRequestException(
            `Product #${line.productId} is no longer available`,
          );
        if (
          product.sizes?.length &&
          line.size &&
          !product.sizes.includes(line.size)
        ) {
          throw new BadRequestException(
            `Size "${line.size}" is not available for "${product.name}"`,
          );
        }
        // Reserve stock now (locks the row; throws if not enough).
        const updated = await this.inventory.adjust(
          em,
          product.id,
          -line.quantity,
          'SALE',
          'Customer order',
        );
        if (updated.stock < LOW_STOCK_THRESHOLD) {
          await this.notifications.create(
            {
              type: 'stock',
              title: 'Low stock',
              message: `"${updated.name}" has ${updated.stock} left`,
            },
            em,
          );
        }
        items.push({
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: line.quantity,
          size: line.size ?? null,
          subtotal: round2(product.price * line.quantity),
        });
      }

      const subtotal = round2(items.reduce((sum, i) => sum + i.subtotal, 0));
      const deliveryFee =
        subtotal >= settings.freeDeliveryThreshold ? 0 : settings.deliveryFee;

      const order = await em.getRepository(Order).save(
        em.getRepository(Order).create({
          customerId: customerId ?? null,
          customerName: dto.customerName.trim(),
          customerEmail: dto.customerEmail.toLowerCase(),
          customerPhone: dto.customerPhone,
          deliveryAddress: dto.deliveryAddress.trim(),
          deliveryCity: dto.deliveryCity.trim(),
          paymentMethod: dto.paymentMethod,
          items,
          subtotal,
          deliveryFee,
          totalAmount: round2(subtotal + deliveryFee),
        }),
      );

      await this.notifications.create(
        {
          type: 'order',
          title: 'New order',
          message: `Order #${order.id} from ${order.customerName}: MK ${order.totalAmount.toLocaleString('en-US')}`,
        },
        em,
      );
      return order;
    });
  }

  findForCustomer(customerId: number): Promise<Order[]> {
    return this.orderRepo.find({
      where: { customerId },
      order: { createdAt: 'DESC' },
    });
  }

  async findOneForCustomer(id: number, customerId: number): Promise<Order> {
    const order = await this.orderRepo.findOne({ where: { id, customerId } });
    if (!order) throw new NotFoundException(`Order #${id} not found`);
    return order;
  }

  /** Public order tracking: needs the order number AND the phone used at checkout. */
  async track(id: number, phone: string) {
    const order = await this.orderRepo.findOne({ where: { id } });
    if (!order || !phone || !samePhone(order.customerPhone, phone)) {
      throw new NotFoundException('No order found with that number and phone');
    }
    return {
      id: order.id,
      status: order.status,
      paymentStatus: order.paymentStatus,
      deliveryCity: order.deliveryCity,
      totalAmount: order.totalAmount,
      items: order.items.map(({ productName, quantity, size }) => ({
        productName,
        quantity,
        size,
      })),
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    };
  }

  // ── Admin ─────────────────────────────────────────────────────

  findAll(status?: string): Promise<Order[]> {
    return this.orderRepo.find({
      where: status ? { status } : {},
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: number): Promise<Order> {
    const order = await this.orderRepo.findOne({ where: { id } });
    if (!order) throw new NotFoundException(`Order #${id} not found`);
    return order;
  }

  /** Cancelling an order puts its items back in stock. */
  updateStatus(id: number, dto: UpdateOrderStatusDto): Promise<Order> {
    return this.dataSource.transaction(async (em) => {
      const order = await em
        .getRepository(Order)
        .findOne({ where: { id }, lock: { mode: 'pessimistic_write' } });
      if (!order) throw new NotFoundException(`Order #${id} not found`);
      if (order.status === 'cancelled' && dto.status !== 'cancelled') {
        throw new BadRequestException(
          'A cancelled order cannot be reopened; ask the customer to order again',
        );
      }
      if (dto.status === 'cancelled' && order.status !== 'cancelled') {
        for (const item of order.items) {
          await this.inventory
            .adjust(
              em,
              item.productId,
              item.quantity,
              'RETURN',
              `Order #${id} cancelled`,
            )
            .catch((err) => {
              // Product was deleted since: nothing to restock.
              if (!(err instanceof NotFoundException)) throw err;
            });
        }
      }
      order.status = dto.status;
      return em.getRepository(Order).save(order);
    });
  }

  async updatePayment(id: number, dto: UpdatePaymentDto): Promise<Order> {
    const order = await this.findOne(id);
    order.paymentStatus = dto.paymentStatus;
    if (dto.transactionId !== undefined)
      order.transactionId = dto.transactionId;
    return this.orderRepo.save(order);
  }

  async getStats() {
    const counts = await this.orderRepo
      .createQueryBuilder('o')
      .select('o.status', 'status')
      .addSelect('COUNT(*)', 'count')
      .groupBy('o.status')
      .getRawMany<{ status: string; count: string }>();
    const byStatus = Object.fromEntries(
      counts.map((c) => [c.status, parseInt(c.count, 10)]),
    );
    const revenue = await this.orderRepo
      .createQueryBuilder('o')
      .select('COALESCE(SUM(o.totalAmount), 0)', 'total')
      .where('o.paymentStatus = :paid', { paid: 'paid' })
      .getRawOne<{ total: string }>();
    return {
      total: Object.values(byStatus).reduce((a, b) => a + b, 0),
      pending: byStatus.pending ?? 0,
      processing: byStatus.processing ?? 0,
      shipped: byStatus.shipped ?? 0,
      delivered: byStatus.delivered ?? 0,
      cancelled: byStatus.cancelled ?? 0,
      totalRevenue: parseFloat(revenue?.total ?? '0'),
    };
  }
}
