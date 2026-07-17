import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('products') // mirrors teammates' products table, we only read from it
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column('decimal', { precision: 10, scale: 2 })
  price: number;

  @Column('int')
  stock: number;
}