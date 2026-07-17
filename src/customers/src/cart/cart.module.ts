import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Cart } from './entities/cart.entity';
import { CartItem } from './entities/cart-item.entity';
import { Product } from './entities/product.entity';
import { CartService } from './cart.service';
import { CartController } from './cart.controller';
import { Wishlist } from './entities/wishlist.entity';
import { WishlistService } from './wishlist.service';
import { WishlistController } from './wishlist.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Cart, CartItem, Product, Wishlist])
  ],
  controllers: [CartController, WishlistController], // registers the controller
  providers: [CartService, WishlistService,],      // registers the service
})
export class CartModule {}