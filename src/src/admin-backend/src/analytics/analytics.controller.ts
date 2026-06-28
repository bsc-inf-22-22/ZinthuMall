import { Controller, Get, UseGuards } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('admin/analytics')
export class AnalyticsController {
  constructor(private analyticsService: AnalyticsService) {}

  @Get('summary')
  getSummary() {
    return this.analyticsService.getSummary();
  }
  
  @Get('revenue')
  getRevenueChart() {
    return this.analyticsService.getRevenueChart();
  }

  @Get('top-products')
  getTopProducts() {
    return this.analyticsService.getTopProducts();
  }
}