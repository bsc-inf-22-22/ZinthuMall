import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('reviews')
export class ReviewView {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  productId!: number;

  @Column()
  productName!: string;

  @Column()
  customerName!: string;

  @Column('int')
  rating!: number;

  @Column({ type: 'text', nullable: true })
  comment!: string;

  @CreateDateColumn()
  createdAt!: Date;
}