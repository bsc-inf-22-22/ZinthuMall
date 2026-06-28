import {Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn} from 'typeorm';
import {Product} from './product.entity';

@Entity('wishlists') // maps to whishlists table in the database
export class Wishlist {
    @PrimaryGeneratedColumn('uuid')
    id!: string;

    @Column()
    customerId!: string; //links whishlist ti customer without login
    // automatically load product details
    @ManyToOne(() => Product, {
        eager: true
    }) 
    product!: Product; //reference to the product the customer saved

    //stores the date the product was added to the whishlis
    @CreateDateColumn()
    createdAt!: Date;

}