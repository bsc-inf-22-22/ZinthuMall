import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { Customer } from './customer.entity';
import { RegisterCustomerDto } from './dto/register-customer.dto';
import { UpdateCustomerDto } from './dto/update-customer.dto';
import { LoginDto } from '../auth/dto/login.dto';
import { JwtPayload } from '../auth/jwt-payload';

@Injectable()
export class CustomersService {
  constructor(
    @InjectRepository(Customer)
    private readonly customerRepo: Repository<Customer>,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterCustomerDto) {
    const email = dto.email.toLowerCase();
    if (await this.customerRepo.exists({ where: { email } })) {
      throw new ConflictException('An account with this email already exists');
    }
    const customer = await this.customerRepo.save(
      this.customerRepo.create({
        name: dto.name.trim(),
        email,
        phone: dto.phone,
        password: await bcrypt.hash(dto.password, 12),
      }),
    );
    return this.authResponse(customer);
  }

  async login(dto: LoginDto) {
    const customer = await this.customerRepo
      .createQueryBuilder('c')
      .addSelect('c.password')
      .where('c.email = :email', { email: dto.email.toLowerCase() })
      .getOne();
    if (!customer || !(await bcrypt.compare(dto.password, customer.password))) {
      throw new UnauthorizedException('Invalid email or password');
    }
    return this.authResponse(customer);
  }

  async findOne(id: number): Promise<Customer> {
    const customer = await this.customerRepo.findOne({ where: { id } });
    if (!customer) throw new NotFoundException('Customer not found');
    return customer;
  }

  async update(id: number, dto: UpdateCustomerDto): Promise<Customer> {
    const customer = await this.findOne(id);
    Object.assign(customer, dto);
    return this.customerRepo.save(customer);
  }

  private authResponse(customer: Customer) {
    const payload: JwtPayload = {
      sub: customer.id,
      email: customer.email,
      role: 'customer',
    };
    return {
      access_token: this.jwtService.sign(payload, { expiresIn: '30d' }),
      customer: {
        id: customer.id,
        name: customer.name,
        email: customer.email,
        phone: customer.phone ?? null,
      },
    };
  }
}
