import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Review } from './review.entity';
import { Product } from '../products/product.entity';
import { Customer } from '../customers/customer.entity';
import { ReviewsService } from './reviews.service';
import {
  AdminReviewsController,
  ReviewsController,
} from './reviews.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Review, Product, Customer])],
  controllers: [ReviewsController, AdminReviewsController],
  providers: [ReviewsService],
})
export class ReviewsModule {}
