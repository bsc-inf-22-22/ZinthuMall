import { Injectable, NotFoundException, BadRequestException} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Order, OrderStatus } from './entities/order.entity';
import { OrderItem } from './entities/order-item.entity';
import { Cart } from '../cart/entities/cart.entity';
import { CartItem } from '../cart/entities/cart-item.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/entities/notification.entity';
@Injectable()
export class OrdersService {
    constructor(
        //give  access to orders, cart, cartItem tables
        @InjectRepository(Order) 
        private orderRepo: Repository<Order>,
        @InjectRepository(Cart)
        private cartRepo: Repository<Cart>,
        @InjectRepository(CartItem)
        private cartItemRepo: Repository<CartItem>,
        private dataSource: DataSource,
        private notificationsService: NotificationsService,
    ) {}
    //POST /api/orders
    async placeOrder(customerId: string) {
        //start a transaction
        const order = await this.dataSource.transaction( async (manager) => {
            //fetch the customer's cart including its items and product details
            const cart = await manager.findOne(Cart, {
                where: { customerId },
                relations : { items : { product : true }},
            });
            //return error if the cart is not found or is empty
            if (!cart || cart.items.length === 0) 
                throw new BadRequestException('The cart is empty');
            //check if there is enough stock for each cart item
            for(const item of cart.items) {
                if (item.product.stock < item.quantity)
                    throw new BadRequestException(`${item.product.name} is out of stock`);
            }
            //add price x quantity to get total order
            const total = cart.items.reduce(
                (sum, item) => sum + item.product.price * item.quantity, 0,
            );
//build order object in memory and convet cart items into order items
        const newOrder = manager.create(Order, {
            customerId,
            total,
            status: OrderStatus.PENDING,
            items : cart.items.map((item) => 
                manager.create(OrderItem, {
                    product: item.product,
                    quantity: item.quantity,
                    priceAtPurchase: item.product.price,
                }),
            ),
        });
        //save the order with its items in database
        await manager.save(newOrder);
        //reduce stock of each product ordered
        for (const item of cart.items) {
            await manager.decrement(
                item.product.constructor, //refers to the product entity
                {id : item.product.id }, //finds this specific product
                'stock', //column to reduce
                item.quantity,
            );
        }
        //empty the cart
        await manager.remove(cart.items);
        return newOrder;
    });
    await this.notificationsService.create(
        customerId,
        'Order placed',
        `Your order of MK ${order.total} is placed successfully`,
        NotificationType.ORDER,
    );
    return order;
    }
  // GET /api/orders/:customerId
  async getOrderHistory(customerId: string) {
    return this.orderRepo.find({
      where: { customerId },
      order: { createdAt: 'DESC' },
    });
  }
//GET /api/orders/: id/details
async getOrderDetails(id: string) {
    //fetch a single order including its items and product details
    const order = await this.orderRepo.findOne( {
        where: {id},
        relations: {items: { product: true }},
    });
    // throw 404 error if no order is found with that id
    if(!order)
        throw new NotFoundException('Order Not Found');
    return order;
        }       
}
