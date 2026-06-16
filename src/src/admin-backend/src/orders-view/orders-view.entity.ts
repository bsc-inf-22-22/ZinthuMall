import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('orders')
export class OrderView {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  customerName!: string;

  @Column()
  customerEmail!: string;

  @Column()
  customerPhone!: string;

  @Column()
  deliveryAddress!: string;

  @Column()
  deliveryCity!: string;

  @Column('decimal', { precision: 10, scale: 2 })
  totalAmount!: number;

  @Column({ default: 'pending' })
  status!: string;

  @Column({ default: 'pending' })
  paymentStatus!: string;

  @Column({ nullable: true })
  paymentMethod!: string;

  @Column({ nullable: true })
  transactionId!: string;

  @Column('jsonb')
  items!: object[];

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}