import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { Notification } from './notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private readonly repo: Repository<Notification>,
  ) {}

  /** Pass `em` to create the notification inside an existing transaction. */
  create(
    data: { title: string; message: string; type: string },
    em?: EntityManager,
  ) {
    const repo = em ? em.getRepository(Notification) : this.repo;
    return repo.save(repo.create(data));
  }

  findAll(): Promise<Notification[]> {
    return this.repo.find({ order: { createdAt: 'DESC' }, take: 200 });
  }

  findUnread(): Promise<Notification[]> {
    return this.repo.find({
      where: { isRead: false },
      order: { createdAt: 'DESC' },
    });
  }

  async getUnreadCount(): Promise<{ count: number }> {
    return { count: await this.repo.count({ where: { isRead: false } }) };
  }

  async markAsRead(id: number): Promise<Notification> {
    const notification = await this.findOne(id);
    notification.isRead = true;
    return this.repo.save(notification);
  }

  async markAllAsRead(): Promise<{ message: string }> {
    await this.repo.update({ isRead: false }, { isRead: true });
    return { message: 'All notifications marked as read' };
  }

  async remove(id: number): Promise<{ message: string }> {
    await this.repo.remove(await this.findOne(id));
    return { message: `Notification #${id} deleted` };
  }

  private async findOne(id: number): Promise<Notification> {
    const notification = await this.repo.findOne({ where: { id } });
    if (!notification)
      throw new NotFoundException(`Notification #${id} not found`);
    return notification;
  }
}
