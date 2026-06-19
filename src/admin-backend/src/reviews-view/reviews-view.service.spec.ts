import { Test, TestingModule } from '@nestjs/testing';
import { ReviewsViewService } from './reviews-view.service';

describe('ReviewsViewService', () => {
  let service: ReviewsViewService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ReviewsViewService],
    }).compile();

    service = module.get<ReviewsViewService>(ReviewsViewService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
