import { IsIn } from 'class-validator';
import { ORDER_STATUSES } from '../order.entity';

export class UpdateOrderStatusDto {
  @IsIn(ORDER_STATUSES)
  status!: string;
}
