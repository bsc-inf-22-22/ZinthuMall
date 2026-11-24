import {
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { WishlistService } from './wishlist.service';
import { CustomerGuard } from '../auth/guards';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtPayload } from '../auth/jwt-payload';

@UseGuards(CustomerGuard)
@Controller('wishlist')
export class WishlistController {
  constructor(private readonly wishlistService: WishlistService) {}

  @Get()
  list(@CurrentUser() user: JwtPayload) {
    return this.wishlistService.list(user.sub);
  }

  @Post(':productId')
  add(
    @CurrentUser() user: JwtPayload,
    @Param('productId', ParseIntPipe) productId: number,
  ) {
    return this.wishlistService.add(user.sub, productId);
  }

  @Delete(':productId')
  remove(
    @CurrentUser() user: JwtPayload,
    @Param('productId', ParseIntPipe) productId: number,
  ) {
    return this.wishlistService.remove(user.sub, productId);
  }
}
