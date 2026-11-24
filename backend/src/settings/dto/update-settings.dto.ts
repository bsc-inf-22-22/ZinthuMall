import {
  IsEmail,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateSettingsDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  storeName?: string;

  @IsOptional()
  @IsEmail()
  storeEmail?: string;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  storePhone?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  storeAddress?: string;

  @IsOptional()
  @IsString()
  @MaxLength(10)
  currency?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  deliveryFee?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  freeDeliveryThreshold?: number;
}
