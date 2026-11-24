import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { decimalTransformer } from '../common/decimal.transformer';

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  name!: string;

  @Index()
  @Column()
  category!: string;

  @Column('decimal', {
    precision: 10,
    scale: 2,
    transformer: decimalTransformer,
  })
  price!: number;

  /** Units in stock. Changed through the inventory module so every change is logged. */
  @Column({ default: 0 })
  stock!: number;

  /** Discount percentage, e.g. 20 = 20% off. */
  @Column({ type: 'int', nullable: true })
  discount?: number | null;

  @Column({ type: 'text', nullable: true })
  description?: string | null;

  @Column('simple-array', { nullable: true })
  sizes?: string[] | null;

  @Column({ type: 'varchar', nullable: true })
  imageUrl?: string | null;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
