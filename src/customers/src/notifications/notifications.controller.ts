import { Controller, Get, Patch, Delete, Param } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
@Controller('api/notifications')
export class NotificationController {
    //inject notifications service so that we can invoke its methods
    constructor(private readonly notificationsService: NotificationsService) {}
    //litsen to GET requests on /api/notifications/:customerId
    @Get(':customerId')
    getAll(
        //extract customerId from URL
        @Param('customerId') customerId: string
    ) {
        return this.notificationsService.getAll(customerId);
    }
    //litsen for GET requests on /apai/notifications/:customerId/unread
    @Get(':customerId/unread')
    getUnread(
        @Param('customerId') customerId: string
    ) {
        return this.notificationsService.getUnread(customerId);
    }
    // listen for PATCH requestes on /api/notifications/:id/read
    @Patch(':id/read')
    markAsRead(
        @Param('id') id: string
    ) {
        return this.notificationsService.markAsRead(id);
    }
    //litsen for PATCH request on /api/notifications/:customerId/read-all
    @Patch(':customerId/read-all')
    markAllAsRead(
        @Param('customerId') customerId: string
    ) {
        return this.notificationsService.markAllAsRead(customerId);
    }
    //listen for delete requests on /api/notificatons/:id
    @Delete(':id')
    delete(
        @Param('id') id: string
    ) {
        return this.notificationsService.delete(id);
    }
}