import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReviewsViewService } from './reviews-view.service';
import { ReviewsViewController } from './reviews-view.controller';
import { ReviewView } from './review-view.entity';

@Module({
  imports: [TypeOrmModule.forFeature([ReviewView])],
  controllers: [ReviewsViewController],
  providers: [ReviewsViewService],
})
export class ReviewsViewModule {}