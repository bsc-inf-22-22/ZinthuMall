import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService implements OnModuleInit {
  public prisma: PrismaClient;

  constructor() {
    // Initialize PrismaClient with proper configuration
    this.prisma = new PrismaClient({
      log: ['error', 'warn'],
    });
  }

  async onModuleInit() {
    await this.prisma.$connect();
    console.log('✅ Database connected successfully');
  }

  async onModuleDestroy() {
    await this.prisma.$disconnect();
  }
}