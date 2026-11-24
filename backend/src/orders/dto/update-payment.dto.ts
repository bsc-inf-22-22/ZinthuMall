import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { PAYMENT_STATUSES } from '../order.entity';

export class UpdatePaymentDto {
  @IsIn(PAYMENT_STATUSES)
  paymentStatus!: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  transactionId?: string;
}
