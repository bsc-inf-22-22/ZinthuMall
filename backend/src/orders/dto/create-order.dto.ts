import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsEmail,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsPositive,
  IsString,
  Matches,
  Max,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { PAYMENT_METHODS } from '../order.entity';

export class CreateOrderItemDto {
  @IsInt()
  @IsPositive()
  productId!: number;

  @IsInt()
  @IsPositive()
  @Max(100)
  quantity!: number;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  size?: string;
}

/**
 * What the app sends at checkout. Prices and totals are NOT accepted
 * from the client; the server works them out from the database.
 */
export class CreateOrderDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  customerName!: string;

  @IsEmail()
  customerEmail!: string;

  @Matches(/^(\+?265|0)\d{8,9}$/, {
    message: 'customerPhone must be a valid Malawi number',
  })
  customerPhone!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  deliveryAddress!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  deliveryCity!: string;

  @IsIn(PAYMENT_METHODS)
  paymentMethod!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items!: CreateOrderItemDto[];
}
