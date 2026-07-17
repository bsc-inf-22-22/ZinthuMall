import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Cart } from './entities/cart.entity';
import { CartItem } from './entities/cart-item.entity';
import { Product } from './entities/product.entity';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';

@Injectable()
export class CartService {
  constructor(
    @InjectRepository(Cart)
    private cartRepo: Repository<Cart>,

    @InjectRepository(CartItem)
    private cartItemRepo: Repository<CartItem>,

    @InjectRepository(Product)
    private productRepo: Repository<Product>,
  ) {}

  // get existing cart or create a new one for this customer
  async getOrCreateCart(customerId: string): Promise<Cart> {
    let cart = await this.cartRepo.findOne({
      where: { customerId },
      relations: { items: { product: true } }, // load items and their products
    });

    if (!cart) {
      cart = this.cartRepo.create({ customerId, items: [] }); // initialize items as empty array
      await this.cartRepo.save(cart);
      cart.items = []; // ensure items is never undefined after creation
    }

    return cart;
  }

  // GET /api/cart/:customerId
  async getCart(customerId: string) {
    const cart = await this.getOrCreateCart(customerId);

    // calculate total price of all items in the cart
    const total = cart.items.reduce(
      (sum, item) => sum + item.product.price * item.quantity,
      0,
    );

    return { ...cart, total };
  }

  // POST /api/cart
  async addItem(dto: AddCartItemDto) {
    const cart = await this.getOrCreateCart(dto.customerId);

    // check product exists
    const product = await this.productRepo.findOne({
      where: { id: dto.productId },
    });
    if (!product) throw new NotFoundException('Product not found');

    // check product has enough stock
    if (product.stock < dto.quantity) {
      throw new BadRequestException('Not enough stock available');
    }

    // if product already in cart, just increase quantity
    const existingItem = cart.items.find(
      (item) => item.product.id === dto.productId,
    );

    if (existingItem) {
      existingItem.quantity += dto.quantity;
      return this.cartItemRepo.save(existingItem);
    }

    // otherwise create a new cart item
    const newItem = this.cartItemRepo.create({
      cart,
      product,
      quantity: dto.quantity,
    });

    return this.cartItemRepo.save(newItem);
  }

  // PATCH /api/cart/:id
  async updateItem(itemId: string, dto: UpdateCartItemDto) {
    const item = await this.cartItemRepo.findOne({
      where: { id: itemId },
      relations: { product: true }, // load product to check stock
    });

    if (!item) throw new NotFoundException('Cart item not found');

    // check stock allows the new quantity
    if (item.product.stock < dto.quantity) {
      throw new BadRequestException('Not enough stock available');
    }

    item.quantity = dto.quantity;
    return this.cartItemRepo.save(item);
  }

  // DELETE /api/cart/:id
  async removeItem(itemId: string) {
    const item = await this.cartItemRepo.findOne({
      where: { id: itemId },
    });

    if (!item) throw new NotFoundException('Cart item not found');

    await this.cartItemRepo.remove(item);
    return { message: 'Item removed from cart' };
  }

  // DELETE /api/cart/clear/:customerId
  async clearCart(customerId: string) {
    const cart = await this.cartRepo.findOne({
      where: { customerId },
      relations: { items: true }, // load items so we can remove them
    });

    if (!cart) throw new NotFoundException('Cart not found');

    await this.cartItemRepo.remove(cart.items);
    return { message: 'Cart cleared successfully' };
  }
}