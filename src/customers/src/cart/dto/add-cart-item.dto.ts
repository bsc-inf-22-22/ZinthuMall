import { IsUUID, IsInt, Min } from 'class-validator';

export class AddCartItemDto {
  @IsUUID()
  productId!: string; // id of the product being added

  @IsUUID()
  customerId!: string; // id of the customer adding the item

  @IsInt()
  @Min(1)
  quantity!: number; // must be at least 1
}