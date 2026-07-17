import { Injectable, NotFoundException, BadRequestException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from 'typeorm';
import { Wishlist } from './entities/wishlist.entity';
import { Product } from './entities/product.entity';

@Injectable()
export class WishlistService {
    constructor(
        //access wishlists table
        @InjectRepository(Wishlist)
        private wishlistRepo: Repository<Wishlist>,
        //acces product table
        @InjectRepository(Product)
        private productRepo: Repository<Product>,
    ) {}
    //POST /api/wishlist
    async addToWishlist(customerId: string, productId: string) {
        //search the products table for the product with the given id
        const product = await this.productRepo.findOne({
            where: {id : productId},
        });
        //throw a 404 error to the client if the product is not found
        if (!product)
            throw new NotFoundException('Product not found');
        //check if the customer already added this product to the wishlist
        const existing = await this.wishlistRepo.findOne({
            where: { customerId, product: {id: productId}},
        });
        //throw 400 error to the client if the product exists to prevent duplicates
        if (existing)
            throw new BadRequestException('Product already exists');
        //create a new wishlist in memory with the customeId and product
        const wishlistItem = this.wishlistRepo.create({
            customerId,
            product,
        });
        //save the new wishlist to the database
        return this.wishlistRepo.save(wishlistItem); 
    }
    //GET /api/wishlist: customerId
    async getWishlist(customerId: string) {
        //fetch wishlist for the customer from the database
        const items = await this.wishlistRepo.find({
            where: { customerId },
        });
        return items
    }
    //DELETE /api/wishlist:id
    async removeFromWishlist(id: string) {
        //fetch the wishlist item with the id
        const item = await this.wishlistRepo.findOne({
            where: {id},
        });
        //throw error if the product is not found otherwise remove it from database
        if(!item)
            throw new NotFoundException('wishlist item not found');
        await this.wishlistRepo.remove(item);
        return {message: 'item removed from wishlist'};
    }
}