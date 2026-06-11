import { Controller, Get, Patch, Param, Body, UseGuards, ParseIntPipe, Query } from '@nestjs/common';
import { OrdersViewService } from './orders-view.service';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('admin/orders')
export class OrdersViewController {
  constructor(private ordersViewService: OrdersViewService) {}

  @Get()
  findAll() {
    return this.ordersViewService.findAll();
  }

  @Get('stats')
  getStats() {
    return this.ordersViewService.getOrderStats();
  }

  @Get('status/:status')
  getByStatus(@Param('status') status: string) {
    return this.ordersViewService.getOrdersByStatus(status);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.ordersViewService.findOne(id);
  }

  @Patch(':id/status')
  updateStatus(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.ordersViewService.updateStatus(id, dto);
  }
}