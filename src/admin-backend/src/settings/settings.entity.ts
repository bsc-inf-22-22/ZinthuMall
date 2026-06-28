import { Entity, PrimaryGeneratedColumn, Column, UpdateDateColumn } from 'typeorm';

@Entity('settings')
export class Setting {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ default: 'Kachipapa Store' })
  storeName!: string;

  @Column({ nullable: true })
  storeEmail!: string;

  @Column({ nullable: true })
  storePhone!: string;

  @Column({ nullable: true })
  storeAddress!: string;

  @Column({ default: 'MK' })
  currency!: string;

  @Column('decimal', { precision: 10, scale: 2, default: 0 })
  deliveryFee!: number;

  @Column('decimal', { precision: 10, scale: 2, default: 30000 })
  freeDeliveryThreshold!: number;

  @UpdateDateColumn()
  updatedAt!: Date;
}