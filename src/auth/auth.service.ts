import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { Admin } from './admin.entity';
import { LoginDto } from './dto/login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(Admin)
    private adminRepo: Repository<Admin>,
    private jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const count = await this.adminRepo.count();
    if (count > 0) {
      throw new ConflictException('Admin already registered');
    }
    const hashed = await bcrypt.hash(dto.password, 12);
    const admin = this.adminRepo.create({ email: dto.email, password: hashed });
    await this.adminRepo.save(admin);
    return { message: 'Admin registered successfully' };
  }

  async login(dto: LoginDto) {
    const admin = await this.adminRepo.findOne({ where: { email: dto.email } });
    if (!admin) throw new UnauthorizedException('Invalid credentials');

    const valid = await bcrypt.compare(dto.password, admin.password);
    if (!valid) throw new UnauthorizedException('Invalid credentials');

    const payload = { sub: admin.id, email: admin.email };
    return { access_token: this.jwtService.sign(payload) };
  }

  async changePassword(adminId: number, dto: ChangePasswordDto) {
    const admin = await this.adminRepo.findOne({ where: { id: adminId } });
    if (!admin) throw new UnauthorizedException();

    const valid = await bcrypt.compare(dto.currentPassword, admin.password);
    if (!valid) throw new UnauthorizedException('Current password is incorrect');

    admin.password = await bcrypt.hash(dto.newPassword, 12);
    await this.adminRepo.save(admin);
    return { message: 'Password updated successfully' };
  }
}