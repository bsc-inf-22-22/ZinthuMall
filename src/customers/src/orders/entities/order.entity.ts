import { Entity, PrimaryGeneratedColumn, Column, OneToMany, CreateDateColumn } from 'typeorm';
import { OrderItem } from './order-item.entity';
//define order states
export enum OrderStatus {
    PENDING = 'pending',
    COMPLETED = 'completed',
    CANCELLED = 'cancelled',
}
@Entity('orders')
export class Order {
    @PrimaryGeneratedColumn('uuid')
    id!: string;
    @Column()
    customerId: string;
    @Column('decimal', { precision: 10, scale: 2})
    total: number; //total price of the order
    @Column({ type: 'enum', enum: OrderStatus, default: OrderStatus.PENDING})
    status: OrderStatus;
    @OneToMany(() => OrderItem, (item: OrderItem) => item.order, {
        cascade: true,
        eager: true
    })
    items: OrderItem[]; // list of products in the order
    @CreateDateColumn()
    createdAt: Date;
}