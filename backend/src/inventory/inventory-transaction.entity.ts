import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Product } from '../products/product.entity';

export type InventoryTransactionType =
  | 'STOCK_IN'
  | 'STOCK_OUT'
  | 'SALE'
  | 'RETURN';

/** Audit log: one row for every change to a product's stock. */
@Entity('inventory_transactions')
export class InventoryTransaction {
  @PrimaryGeneratedColumn()
  id!: number;

  @Index()
  @Column()
  productId!: number;

  @ManyToOne(() => Product, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'productId' })
  product?: Product;

  /** Positive for stock added, negative for stock removed. */
  @Column()
  quantity!: number;

  @Column({ type: 'varchar', length: 20 })
  type!: InventoryTransactionType;

  @Column({ type: 'varchar', nullable: true })
  notes?: string | null;

  @CreateDateColumn()
  createdAt!: Date;
}
