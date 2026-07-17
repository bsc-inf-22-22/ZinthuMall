import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Order } from './entities/order.entity';
import { OrderItem } from './entities/order-item.entity'
import { Cart } from '../cart/entities/cart.entity';
import { CartItem } from '../cart/entities/cart-item.entity';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { NotificationsModule } from '../notifications/notifications.module';
@Module({
    imports: [
        //register all orders related entities
        TypeOrmModule.forFeature([Order, OrderItem, Cart, CartItem]),
        NotificationsModule,
    ],
    //register the controller and service
    controllers: [OrdersController],
    providers: [OrdersService],
})
export class OrdersModule {}