import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from './notifications.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private notificationRepo: Repository<Notification>,
  ) {}

  async findAll(): Promise<Notification[]> {
    return this.notificationRepo.find({ order: { createdAt: 'DESC' } });
  }

  async findUnread(): Promise<Notification[]> {
    return this.notificationRepo.find({
      where: { IsRead: false },
      order: { createdAt: 'DESC' },
    });
  }

  async markAsRead(id: number): Promise<Notification> {
    const notification = await this.notificationRepo.findOne({ where: { id } });
    if (!notification) throw new NotFoundException(`Notification #${id} not found`);
    notification.IsRead = true;
    return this.notificationRepo.save(notification);
  }

  async markAllAsRead(): Promise<{ message: string }> {
    await this.notificationRepo
      .createQueryBuilder()
      .update(Notification)
      .set({ IsRead: true })
      .where('IsRead = :IsRead', { IsRead: false })
      .execute();
    return { message: 'All notifications marked as read' };
  }

  async remove(id: number): Promise<{ message: string }> {
    const notification = await this.notificationRepo.findOne({ where: { id } });
    if (!notification) throw new NotFoundException(`Notification #${id} not found`);
    await this.notificationRepo.remove(notification);
    return { message: `Notification #${id} deleted successfully` };
  }

  async getUnreadCount(): Promise<{ count: number }> {
    const count = await this.notificationRepo.count({ where: { IsRead: false } });
    return { count };
  }
}