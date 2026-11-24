import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { Product } from '../products/product.entity';

@Entity('reviews')
@Unique(['customerId', 'productId'])
export class Review {
  @PrimaryGeneratedColumn()
  id!: number;

  @Index()
  @Column()
  productId!: number;

  @ManyToOne(() => Product, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'productId' })
  product?: Product;

  @Column()
  productName!: string;

  @Column({ type: 'int', nullable: true })
  customerId?: number | null;

  @Column()
  customerName!: string;

  @Column('int')
  rating!: number;

  @Column({ type: 'text', nullable: true })
  comment?: string | null;

  @CreateDateColumn()
  createdAt!: Date;
}
