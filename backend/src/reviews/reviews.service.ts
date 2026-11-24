import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review } from './review.entity';
import { CreateReviewDto } from './dto/create-review.dto';
import { Product } from '../products/product.entity';
import { Customer } from '../customers/customer.entity';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class ReviewsService {
  constructor(
    @InjectRepository(Review) private readonly repo: Repository<Review>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(Customer)
    private readonly customerRepo: Repository<Customer>,
    private readonly notifications: NotificationsService,
  ) {}

  async create(customerId: number, dto: CreateReviewDto): Promise<Review> {
    const product = await this.productRepo.findOne({
      where: { id: dto.productId },
    });
    if (!product)
      throw new NotFoundException(`Product #${dto.productId} not found`);
    const customer = await this.customerRepo.findOneOrFail({
      where: { id: customerId },
    });
    if (
      await this.repo.exists({ where: { customerId, productId: product.id } })
    ) {
      throw new ConflictException('You have already reviewed this product');
    }
    const review = await this.repo.save(
      this.repo.create({
        productId: product.id,
        productName: product.name,
        customerId,
        customerName: customer.name,
        rating: dto.rating,
        comment: dto.comment?.trim() || null,
      }),
    );
    await this.notifications.create({
      type: 'review',
      title: 'New review',
      message: `${customer.name} rated "${product.name}" ${dto.rating}/5`,
    });
    return review;
  }

  findForCustomer(customerId: number): Promise<Review[]> {
    return this.repo.find({
      where: { customerId },
      order: { createdAt: 'DESC' },
    });
  }

  findByProduct(productId: number): Promise<Review[]> {
    return this.repo.find({
      where: { productId },
      order: { createdAt: 'DESC' },
    });
  }

  async summaryForProduct(productId: number) {
    const row = await this.repo
      .createQueryBuilder('r')
      .select('COUNT(*)', 'count')
      .addSelect('COALESCE(AVG(r.rating), 0)', 'avg')
      .where('r.productId = :productId', { productId })
      .getRawOne<{ count: string; avg: string }>();
    return {
      reviewCount: parseInt(row?.count ?? '0', 10),
      rating: Math.round(parseFloat(row?.avg ?? '0') * 10) / 10,
    };
  }

  findAll(): Promise<Review[]> {
    return this.repo.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: number): Promise<Review> {
    const review = await this.repo.findOne({ where: { id } });
    if (!review) throw new NotFoundException(`Review #${id} not found`);
    return review;
  }

  async getStats() {
    const row = await this.repo
      .createQueryBuilder('r')
      .select('COUNT(*)', 'count')
      .addSelect('COALESCE(AVG(r.rating), 0)', 'avg')
      .getRawOne<{ count: string; avg: string }>();
    return {
      totalReviews: parseInt(row?.count ?? '0', 10),
      averageRating: Math.round(parseFloat(row?.avg ?? '0') * 10) / 10,
    };
  }

  async remove(id: number): Promise<{ message: string }> {
    await this.repo.remove(await this.findOne(id));
    return { message: `Review #${id} deleted` };
  }
}
