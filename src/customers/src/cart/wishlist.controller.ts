import { Controller, Get, Post, Delete, Param, Body} from '@nestjs/common';
import { WishlistService } from './wishlist.service';
import { IsUUID } from 'class-validator';
//define shape of request to add to the wishlist
class AddToWishlistDto {
    @IsUUID()
    customerId!: string;
    @IsUUID()
    productId!: string;
}

@Controller('api/wishlist')
export class WishlistController {
    //inject Wishlist servise so that we can call its methods
    constructor(private readonly wishlistService: WishlistService) {}
    //listen for POST request at api/wishlist
    @Post()
    addToWishlist(
        @Body() dto: AddToWishlistDto
    ) {
        return this.wishlistService.addToWishlist(dto.customerId, dto.productId);
    }
    //listen for GET requests on /api/wishlist/:customerId
    @Get(':customerId')
    getWishlist(
        @Param('customerId') customerId: string  // extract cusomerId from the URL
    ) {
        return this.wishlistService.getWishlist(customerId); 
    }
    //listen for DELETE requests on /api/wishlis/:id
    @Delete(':id')
    removeFromWishlist(
        @Param('id') id: string  //extract wishlist item id from the URL
    ) {
        return this.wishlistService.removeFromWishlist(id);
    }
}
