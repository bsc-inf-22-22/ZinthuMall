import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AnalyticsService } from './analytics.service';
import { AnalyticsController } from './analytics.controller';
import { Product } from '../products/products.entity';
import { OrderView } from '../orders-view/orders-view.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Product, OrderView])],
  controllers: [AnalyticsController],
  providers: [AnalyticsService],
})
export class AnalyticsModule {}