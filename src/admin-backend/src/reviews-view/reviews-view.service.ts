import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ReviewView } from './review-view.entity';

@Injectable()
export class ReviewsViewService {
  constructor(
    @InjectRepository(ReviewView)
    private reviewRepo: Repository<ReviewView>,
  ) {}

  async findAll(): Promise<ReviewView[]> {
    return this.reviewRepo.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: number): Promise<ReviewView> {
    const review = await this.reviewRepo.findOne({ where: { id } });
    if (!review) throw new NotFoundException(`Review #${id} not found`);
    return review;
  }

  async findByProduct(productId: number): Promise<ReviewView[]> {
    return this.reviewRepo.find({
      where: { productId },
      order: { createdAt: 'DESC' },
    });
  }

  async getStats() {
    const total = await this.reviewRepo.count();

    const result = await this.reviewRepo
      .createQueryBuilder('review')
      .select('AVG(review.rating)', 'avgRating')
      .getRawOne();

    const avgRating = parseFloat(result.avgRating) || 0;

    return {
      totalReviews: total,
      averageRating: Math.round(avgRating * 10) / 10,
    };
  }

  async remove(id: number): Promise<{ message: string }> {
    const review = await this.findOne(id);
    await this.reviewRepo.remove(review);
    return { message: `Review #${id} deleted successfully` };
  }
}