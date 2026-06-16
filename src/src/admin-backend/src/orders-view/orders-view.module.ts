import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrdersViewService } from './orders-view.service';
import { OrdersViewController } from './orders-view.controller';
import { OrderView } from './orders-view.entity';

@Module({
  imports: [TypeOrmModule.forFeature([OrderView])],
  controllers: [OrdersViewController],
  providers: [OrdersViewService],
})
export class OrdersViewModule {}