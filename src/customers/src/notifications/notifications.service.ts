import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification, NotificationType } from './entities/notification.entity';
@Injectable()
export class NotificationsService {
    constructor(
        //inject the Notification repository giving access to notifications table
        @InjectRepository(Notification)
        private notificationRepo: Repository<Notification>,
    ) {}
    //create a notification for an event
    async create(customerId: string, title: string, message: string, type: NotificationType) {
        const notification = this.notificationRepo.create({
            customerId,
            title,
            message,
            type,
            isRead: false,
        });
        return this.notificationRepo.save(notification);
    }
    //GET /api/notifications/:customerId
    async getAll(customerId: string) {
        //fetch all notifications belonging to the customer
        return this.notificationRepo.find({
            where: { customerId },
            //sort so thgat newest notifications appear first
            order: { createdAt: 'DESC' },
        });
    }
    //GET /api/notifications/:customerId/unread
    async getUnread(customerId: string) {
        //fetch only notifications where isRead is false
        return this.notificationRepo.find({
            where: { customerId, isRead: false },
            order: { createdAt: 'DESC' },
        });
    }
    //PATCH /api/notifications/:id/read
    async markAsRead(id: string) {
        //find a specific notification by its id
        const notification = await this.notificationRepo.findOne({
            where: { id },
        });
        //throw an error if not found
        if (!notification)
            throw new NotFoundException('Notification not found');
        //make isRead true and update in the database
        notification.isRead = true;
        return this.notificationRepo.save(notification);
    }
    //PATCH /api/notifications/:customerId/read-all
    async markAllAsRead(customerId: string) {
        //update every unread customer notification
        await this.notificationRepo.update(
            { customerId, isRead: false },
            {isRead: true},
        );
        return {message: 'All notifications marked as read'};
    }
    //DELETE /api/notifications/:id
    async delete(id: string) {
        //find notification by its id
        const notification = await this.notificationRepo.findOne({
            where: { id },
        });
        //return error if the notification is not found
        if(!notification)
            throw new NotFoundException('Notification not found');
        //delete notification from the database
        await this.notificationRepo.remove(notification);
        return { message: 'Notification deleted' };
    }
}