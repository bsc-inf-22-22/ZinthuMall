import { IsInt, IsPositive, IsOptional, IsString } from 'class-validator';

export class AddStockDto {
  @IsInt()
  @IsPositive()
  productId!: number;

  @IsInt()
  @IsPositive()
  quantity!: number;

  @IsOptional()
  @IsString()
  notes?: string;
}