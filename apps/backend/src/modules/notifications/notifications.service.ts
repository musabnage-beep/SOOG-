import { Inject, Injectable } from '@nestjs/common';
import { NotificationType, Prisma } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import {
  MAIL_PROVIDER,
  MailProvider,
  PUSH_PROVIDER,
  PushProvider,
} from '@/integrations/messaging/messaging.interface';

export interface NotifyInput {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  payload?: Prisma.InputJsonValue;
  /** Also send a push notification to the user's devices. Default true. */
  push?: boolean;
  /** Also send an email if the user has one. Default false. */
  email?: boolean;
}

@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(PUSH_PROVIDER) private readonly pushProvider: PushProvider,
    @Inject(MAIL_PROVIDER) private readonly mailProvider: MailProvider,
  ) {}

  /** Persists an in-app notification and fans out to push/email channels. */
  async notify(input: NotifyInput): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: input.userId },
      select: { id: true, email: true, fcmTokens: true },
    });
    if (!user) return;

    await this.prisma.notification.create({
      data: {
        userId: input.userId,
        type: input.type,
        channel: 'IN_APP',
        title: input.title,
        body: input.body,
        payload: input.payload ?? Prisma.JsonNull,
      },
    });

    if (input.push !== false && user.fcmTokens.length > 0) {
      await this.pushProvider.send({
        tokens: user.fcmTokens,
        title: input.title,
        body: input.body,
        data: { type: input.type },
      });
    }

    if (input.email && user.email) {
      await this.mailProvider.send({
        to: user.email,
        subject: input.title,
        html: `<p>${input.body}</p>`,
        text: input.body,
      });
    }
  }

  async listForUser(userId: string, unreadOnly = false) {
    return this.prisma.notification.findMany({
      where: { userId, ...(unreadOnly ? { isRead: false } : {}) },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }

  async unreadCount(userId: string): Promise<number> {
    return this.prisma.notification.count({ where: { userId, isRead: false } });
  }

  async markRead(userId: string, id: string): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { id, userId },
      data: { isRead: true },
    });
  }

  async markAllRead(userId: string): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
  }
}
