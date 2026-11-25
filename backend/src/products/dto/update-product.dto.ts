import { PartialType } from '@nestjs/mapped-types';
import { IsArray, IsOptional, IsString } from 'class-validator';
import { Transform } from 'class-transformer';
import { CreateProductDto, toStringArray } from './create-product.dto';

export class UpdateProductDto extends PartialType(CreateProductDto) {
  /** Photos to delete from the product (URLs as returned in imageUrls). */
  @IsOptional()
  @Transform(toStringArray)
  @IsArray()
  @IsString({ each: true })
  removeImageUrls?: string[];
}
