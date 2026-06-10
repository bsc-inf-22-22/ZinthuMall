import { IsString, IsNumber, IsOptional, IsArray, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateProductDto {
  @IsString()
  name!: string;

  @IsString()
  category!: string;

  @IsNumber()
  @Type(() => Number)
  price!: number;

  @IsNumber()
  @Type(() => Number)
  stock!: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  discount?: number;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsArray()
  sizes?: string[];
}