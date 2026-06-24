import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { PushMessage, PushProvider } from './messaging.interface';

/** Dev push provider: logs the payload. */
@Injectable()
export class ConsolePushProvider implements PushProvider {
  private readonly logger = new Logger('PUSH');

  async send(message: PushMessage): Promise<void> {
    this.logger.log(
      `[DEV-PUSH] tokens=${message.tokens.length} title="${message.title}" body="${message.body}"`,
    );
  }
}

/** Production push provider via Firebase Cloud Messaging. */
@Injectable()
export class FcmPushProvider implements PushProvider {
  private readonly logger = new Logger('PUSH');

  constructor(config: ConfigService) {
    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: config.getOrThrow<string>('FIREBASE_PROJECT_ID'),
          clientEmail: config.getOrThrow<string>('FIREBASE_CLIENT_EMAIL'),
          privateKey: config.getOrThrow<string>('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n'),
        }),
      });
    }
  }

  async send(message: PushMessage): Promise<void> {
    if (message.tokens.length === 0) return;
    const res = await admin.messaging().sendEachForMulticast({
      tokens: message.tokens,
      notification: { title: message.title, body: message.body },
      data: message.data,
    });
    if (res.failureCount > 0) {
      this.logger.warn(`FCM: ${res.failureCount}/${message.tokens.length} failed`);
    }
  }
}
