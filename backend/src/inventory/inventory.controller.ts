import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { AdjustStockDto } from './dto/adjust-stock.dto';
import { AdminGuard } from '../auth/guards';

@UseGuards(AdminGuard)
@Controller('inventory')
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  @Get()
  getAll() {
    return this.inventoryService.getAll();
  }

  @Get('low-stock')
  getLowStock() {
    return this.inventoryService.getLowStock();
  }

  @Get('out-of-stock')
  getOutOfStock() {
    return this.inventoryService.getOutOfStock();
  }

  @Post('add-stock')
  addStock(@Body() dto: AdjustStockDto) {
    return this.inventoryService.addStock(dto);
  }

  @Post('reduce-stock')
  reduceStock(@Body() dto: AdjustStockDto) {
    return this.inventoryService.reduceStock(dto);
  }

  @Get('history/:productId')
  getHistory(@Param('productId', ParseIntPipe) productId: number) {
    return this.inventoryService.getHistory(productId);
  }
}
