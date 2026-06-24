import { Controller, Get, Param, Patch, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { NotificationsService } from './notifications.service';

@ApiTags('Notifications')
@ApiBearerAuth()
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  @Get()
  list(@CurrentUser('id') userId: string, @Query('unreadOnly') unreadOnly?: string) {
    return this.service.listForUser(userId, unreadOnly === 'true');
  }

  @Get('unread-count')
  async unreadCount(@CurrentUser('id') userId: string) {
    return { count: await this.service.unreadCount(userId) };
  }

  @Patch(':id/read')
  async markRead(@CurrentUser('id') userId: string, @Param('id') id: string) {
    await this.service.markRead(userId, id);
    return { ok: true };
  }

  @Patch('read-all')
  async markAllRead(@CurrentUser('id') userId: string) {
    await this.service.markAllRead(userId);
    return { ok: true };
  }
}
