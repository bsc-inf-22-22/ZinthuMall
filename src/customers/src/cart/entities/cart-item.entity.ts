import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { Cart } from './cart.entity';
import { Product } from './product.entity';

@Entity('cart_items')
export class CartItem {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => Cart, (cart) => cart.items, {
    onDelete: 'CASCADE' // if cart is deleted, its items are deleted too
  })
  cart!: Cart;

  @ManyToOne(() => Product, { eager: true }) // product details loaded automatically
  product!: Product;

  @Column('int')
  quantity!: number;
}