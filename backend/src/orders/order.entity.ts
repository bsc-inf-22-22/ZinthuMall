import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { decimalTransformer } from '../common/decimal.transformer';

export const ORDER_STATUSES = [
  'pending',
  'processing',
  'shipped',
  'delivered',
  'cancelled',
] as const;
export const PAYMENT_STATUSES = [
  'pending',
  'paid',
  'failed',
  'refunded',
] as const;
export const PAYMENT_METHODS = ['airtel_money', 'tnm_mpamba', 'cash'] as const;

export interface OrderItem {
  productId: number;
  productName: string;
  price: number;
  quantity: number;
  size: string | null;
  subtotal: number;
}

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn()
  id!: number;

  /** Set when a logged-in customer places the order; null for guest checkout. */
  @Index()
  @Column({ type: 'int', nullable: true })
  customerId?: number | null;

  @Column()
  customerName!: string;

  @Column({ type: 'varchar', nullable: true })
  customerEmail?: string | null;

  @Column()
  customerPhone!: string;

  @Column()
  deliveryAddress!: string;

  @Column()
  deliveryCity!: string;

  @Column('decimal', {
    precision: 10,
    scale: 2,
    default: 0,
    transformer: decimalTransformer,
  })
  subtotal!: number;

  @Column('decimal', {
    precision: 10,
    scale: 2,
    default: 0,
    transformer: decimalTransformer,
  })
  deliveryFee!: number;

  @Column('decimal', {
    precision: 10,
    scale: 2,
    transformer: decimalTransformer,
  })
  totalAmount!: number;

  @Index()
  @Column({ default: 'pending' })
  status!: string;

  @Column({ default: 'pending' })
  paymentStatus!: string;

  @Column({ type: 'varchar', nullable: true })
  paymentMethod?: string | null;

  /** Mobile-money reference, entered when payment is confirmed. */
  @Column({ type: 'varchar', nullable: true })
  transactionId?: string | null;

  @Column('jsonb')
  items!: OrderItem[];

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
