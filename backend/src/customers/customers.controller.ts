import { Body, Controller, Get, Patch, Post, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { CustomersService } from './customers.service';
import { RegisterCustomerDto } from './dto/register-customer.dto';
import { UpdateCustomerDto } from './dto/update-customer.dto';
import { LoginDto } from '../auth/dto/login.dto';
import { CustomerGuard } from '../auth/guards';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtPayload } from '../auth/jwt-payload';

@Controller('customer')
export class CustomersController {
  constructor(private readonly customersService: CustomersService) {}

  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @Post('auth/register')
  register(@Body() dto: RegisterCustomerDto) {
    return this.customersService.register(dto);
  }

  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @Post('auth/login')
  login(@Body() dto: LoginDto) {
    return this.customersService.login(dto);
  }

  @UseGuards(CustomerGuard)
  @Get('profile')
  profile(@CurrentUser() user: JwtPayload) {
    return this.customersService.findOne(user.sub);
  }

  @UseGuards(CustomerGuard)
  @Patch('profile')
  updateProfile(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateCustomerDto,
  ) {
    return this.customersService.update(user.sub, dto);
  }
}
