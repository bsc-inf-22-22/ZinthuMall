import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class RegisterCustomerDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name!: string;

  @IsEmail()
  email!: string;

  @MinLength(8)
  password!: string;

  /** Malawi numbers, e.g. 0991234567 or +265991234567 */
  @IsOptional()
  @Matches(/^(\+?265|0)\d{8,9}$/, {
    message: 'phone must be a valid Malawi number',
  })
  phone?: string;
}
