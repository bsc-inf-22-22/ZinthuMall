import { Controller, Get } from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';
import { DataSource } from 'typeorm';

@SkipThrottle()
@Controller()
export class AppController {
  constructor(private readonly dataSource: DataSource) {}

  /** Health check used by Render/Railway to know the service is up. */
  @Get('health')
  async health() {
    await this.dataSource.query('SELECT 1');
    return { status: 'ok' };
  }
}
