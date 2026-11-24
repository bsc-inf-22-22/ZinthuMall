import {
  Body,
  Controller,
  Headers,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { RegisterDto } from './dto/register.dto';
import { AdminGuard } from './guards';
import { CurrentUser } from './current-user.decorator';
import { JwtPayload } from './jwt-payload';

@Controller('admin/auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * Creates the FIRST admin account only. Requires the X-Setup-Key
   * header to match the ADMIN_SETUP_KEY environment variable.
   */
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @Post('register')
  register(
    @Body() dto: RegisterDto,
    @Headers('x-setup-key') setupKey?: string,
  ) {
    return this.authService.register(dto, setupKey);
  }

  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @UseGuards(AdminGuard)
  @Patch('password')
  changePassword(
    @CurrentUser() user: JwtPayload,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.authService.changePassword(user.sub, dto);
  }
}
