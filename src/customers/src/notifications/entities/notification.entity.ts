import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';
//define allowed values for notification type
export enum NotificationType {
    ORDER = 'order',
    PAYMENT = 'payment',
    DERIVERY = 'delivery',
}
//map to notifications table in the database
@Entity('notifications')
export class Notification {
    @PrimaryGeneratedColumn('uuid')
    id!: string;
    @Column()
    customerId!: string;
    @Column()
    title!: string;
    @Column('text')
    message!: string;
    @Column({type: 'enum', enum: NotificationType })
    type!: NotificationType;
    @Column({default: false})
    isRead!: boolean;
    @CreateDateColumn()
    createdAt!: Date;
}