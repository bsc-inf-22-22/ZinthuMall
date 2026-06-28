import { Test, TestingModule } from '@nestjs/testing';
import { OrdersViewController } from './orders-view.controller';

describe('OrdersViewController', () => {
  let controller: OrdersViewController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [OrdersViewController],
    }).compile();

    controller = module.get<OrdersViewController>(OrdersViewController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
