import { Test, TestingModule } from '@nestjs/testing';
import { OrdersViewService } from './orders-view.service';

describe('OrdersViewService', () => {
  let service: OrdersViewService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [OrdersViewService],
    }).compile();

    service = module.get<OrdersViewService>(OrdersViewService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
