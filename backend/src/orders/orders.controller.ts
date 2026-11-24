import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { CustomerGuard, OptionalAuthGuard } from '../auth/guards';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtPayload } from '../auth/jwt-payload';

/** Customer-facing order endpoints. */
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  /** Checkout. Works for guests; links the order to the customer if logged in. */
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @UseGuards(OptionalAuthGuard)
  @Post()
  place(@Body() dto: CreateOrderDto, @CurrentUser() user?: JwtPayload) {
    return this.ordersService.place(
      dto,
      user?.role === 'customer' ? user.sub : undefined,
    );
  }

  @UseGuards(CustomerGuard)
  @Get('mine')
  mine(@CurrentUser() user: JwtPayload) {
    return this.ordersService.findForCustomer(user.sub);
  }

  @Throttle({ default: { ttl: 60_000, limit: 20 } })
  @Get('track/:id')
  track(@Param('id', ParseIntPipe) id: number, @Query('phone') phone: string) {
    return this.ordersService.track(id, phone);
  }

  @UseGuards(CustomerGuard)
  @Get('mine/:id')
  mineOne(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.ordersService.findOneForCustomer(id, user.sub);
  }
}
