import { Controller, Get, Post, Patch, Delete, Param, Body } from '@nestjs/common';
import { CartService } from './cart.service';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';


@Controller('api/cart')
export class CartController {
  constructor(private readonly cartService: CartService) {}

  // GET /api/cart/:customerId — get a customer's cart
  @Get(':customerId')
  getCart(@Param('customerId') customerId: string) {
    return this.cartService.getCart(customerId);
  }

  // POST /api/cart — add item to cart
  @Post()
  addItem(@Body() dto: AddCartItemDto) {
    return this.cartService.addItem(dto);
  }

  // PATCH /api/cart/:id — update item quantity
  @Patch(':id')
  updateItem(@Param('id') id: string, @Body() dto: UpdateCartItemDto) {
    return this.cartService.updateItem(id, dto);
  }

  // DELETE /api/cart/:id — remove a single item
  @Delete(':id')
  removeItem(@Param('id') id: string) {
    return this.cartService.removeItem(id);
  }

  // DELETE /api/cart/clear/:customerId — clear entire cart
  @Delete('clear/:customerId')
  clearCart(@Param('customerId') customerId: string) {
    return this.cartService.clearCart(customerId);
  }
}