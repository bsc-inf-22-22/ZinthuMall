import { Test, TestingModule } from '@nestjs/testing';
import { ReviewsViewController } from './reviews-view.controller';

describe('ReviewsViewController', () => {
  let controller: ReviewsViewController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ReviewsViewController],
    }).compile();

    controller = module.get<ReviewsViewController>(ReviewsViewController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
