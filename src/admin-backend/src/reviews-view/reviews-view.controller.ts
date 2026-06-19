import { Controller, Get, Delete, Param, UseGuards, ParseIntPipe } from '@nestjs/common';
import { ReviewsViewService } from './reviews-view.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('admin/reviews')
export class ReviewsViewController {
  constructor(private reviewsViewService: ReviewsViewService) {}

  @Get()
  findAll() {
    return this.reviewsViewService.findAll();
  }

  @Get('stats')
  getStats() {
    return this.reviewsViewService.getStats();
  }

  @Get('product/:productId')
  findByProduct(@Param('productId', ParseIntPipe) productId: number) {
    return this.reviewsViewService.findByProduct(productId);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.reviewsViewService.findOne(id);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.reviewsViewService.remove(id);
  }
}