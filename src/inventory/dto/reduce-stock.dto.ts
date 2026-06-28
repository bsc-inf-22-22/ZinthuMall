import { IsInt, IsPositive, IsOptional, IsString } from 'class-validator';

export class ReduceStockDto {
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