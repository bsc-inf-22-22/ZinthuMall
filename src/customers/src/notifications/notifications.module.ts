import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Notification } from "./entities/notification.entity";
import { NotificationsService } from "./notifications.service";
import { NotificationController } from "./notifications.controller";
@Module({
    imports: [
        TypeOrmModule.forFeature([Notification])
    ],
    controllers: [NotificationController],
    providers: [NotificationsService],
    exports: [ NotificationsService],
})
export class NotificationsModule {}