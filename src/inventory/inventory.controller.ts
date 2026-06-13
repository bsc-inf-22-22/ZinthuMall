import { Controller, Get, Post, Body, Param, ParseIntPipe } from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { AddStockDto } from './dto/add-stock.dto';
import { ReduceStockDto } from './dto/reduce-stock.dto';

@Controller('inventory')
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  // GET /inventory - Display current stock quantities
  @Get()
  async getAllInventory() {
    return this.inventoryService.getAllInventory();
  }

  // GET /inventory/low-stock - Get low stock products (<5 units)
  @Get('low-stock')
  async getLowStock() {
    return this.inventoryService.getLowStockProducts();
  }

  // GET /inventory/out-of-stock - Get out of stock products (0 units)
  @Get('out-of-stock')
  async getOutOfStock() {
    return this.inventoryService.getOutOfStockProducts();
  }

  // POST /inventory/add-stock - Add stock to a product
  @Post('add-stock')
  async addStock(@Body() addStockDto: AddStockDto) {
    return this.inventoryService.addStock(addStockDto);
  }

  // POST /inventory/reduce-stock - Reduce stock (for orders or adjustments)
  @Post('reduce-stock')
  async reduceStock(@Body() reduceStockDto: ReduceStockDto) {
    return this.inventoryService.reduceStock(reduceStockDto);
  }

  // GET /inventory/history/:productId - Get transaction history for a product
  @Get('history/:productId')
  async getTransactionHistory(@Param('productId', ParseIntPipe) productId: number) {
    return this.inventoryService.getTransactionHistory(productId);
  }
}