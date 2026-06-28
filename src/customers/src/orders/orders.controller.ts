import { Controller, Post, Get, Param, Body } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { IsUUID } from 'class-validator';
//Dto to validate the request body when placing an order
class PlaceOrderDto {
    @IsUUID()
    customerId!: string;
}
@Controller('api/orders') // base route for orders endpoints
export class OrdersController {
    //inject orderService
    constructor(private readonly ordersService: OrdersService) {}
    //POST /api/orders - place an order from the customer's cart
    @Post()
    placeOrder(@Body() dto: PlaceOrderDto) {
        return this.ordersService.placeOrder(dto.customerId);
    }
    //GET /api/orders/:customerId- return all orders of the customer
    @Get(':customerId')
    getOrderHistory(@Param('customerId') customerId: string) {
        return this.ordersService.getOrderHistory(customerId);
    }
    //GET api/orders/:id/details     -get a single order with all details
    @Get(':id/details')
    getOrderDetails(@Param('id') id: string) {
        return this.ordersService.getOrderDetails(id);
    }

}