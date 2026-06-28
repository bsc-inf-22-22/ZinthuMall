import { Entity, PrimaryGeneratedColumn, Column, OneToMany, CreateDateColumn } from 'typeorm';
import { CartItem } from './cart-item.entity';

@Entity('carts')
export class Cart {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  customerId: string; // links cart to a customer without requiring login

  @OneToMany(() => CartItem, (item) => item.cart, {
    cascade: true, // saving cart also saves its items
    eager: true    // items are automatically loaded with the cart
  })
  items: CartItem[];

  @CreateDateColumn()
  createdAt: Date;
}