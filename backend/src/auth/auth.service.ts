import {
  ConflictException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { Admin } from './admin.entity';
import { LoginDto } from './dto/login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { RegisterDto } from './dto/register.dto';
import { JwtPayload } from './jwt-payload';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(Admin) private readonly adminRepo: Repository<Admin>,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(dto: RegisterDto, setupKey?: string) {
    const expectedKey = this.config.get<string>('ADMIN_SETUP_KEY');
    if (expectedKey && setupKey !== expectedKey) {
      throw new ForbiddenException('Invalid setup key');
    }
    if ((await this.adminRepo.count()) > 0) {
      throw new ConflictException('An admin account already exists');
    }
    const admin = this.adminRepo.create({
      email: dto.email.toLowerCase(),
      password: await bcrypt.hash(dto.password, 12),
    });
    await this.adminRepo.save(admin);
    return { message: 'Admin registered successfully' };
  }

  async login(dto: LoginDto) {
    const admin = await this.adminRepo.findOne({
      where: { email: dto.email.toLowerCase() },
    });
    if (!admin || !(await bcrypt.compare(dto.password, admin.password))) {
      throw new UnauthorizedException('Invalid credentials');
    }
    const payload: JwtPayload = {
      sub: admin.id,
      email: admin.email,
      role: 'admin',
    };
    return { access_token: this.jwtService.sign(payload) };
  }

  async changePassword(adminId: number, dto: ChangePasswordDto) {
    const admin = await this.adminRepo.findOne({ where: { id: adminId } });
    if (!admin) throw new UnauthorizedException();
    if (!(await bcrypt.compare(dto.currentPassword, admin.password))) {
      throw new UnauthorizedException('Current password is incorrect');
    }
    admin.password = await bcrypt.hash(dto.newPassword, 12);
    await this.adminRepo.save(admin);
    return { message: 'Password updated successfully' };
  }
}
