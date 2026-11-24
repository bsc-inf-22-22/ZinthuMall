import { Column, Entity, PrimaryColumn, UpdateDateColumn } from 'typeorm';
import { decimalTransformer } from '../common/decimal.transformer';

/** Store-wide settings. There is always exactly one row (id = 1). */
@Entity('settings')
export class Setting {
  @PrimaryColumn({ default: 1 })
  id!: number;

  @Column({ default: 'Kachipapa Store' })
  storeName!: string;

  @Column({ type: 'varchar', nullable: true })
  storeEmail?: string | null;

  @Column({ type: 'varchar', nullable: true })
  storePhone?: string | null;

  @Column({ type: 'varchar', nullable: true })
  storeAddress?: string | null;

  @Column({ default: 'MK' })
  currency!: string;

  /** Charged when the order subtotal is below freeDeliveryThreshold. */
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
    default: 5000,
    transformer: decimalTransformer,
  })
  freeDeliveryThreshold!: number;

  @UpdateDateColumn()
  updatedAt!: Date;
}
