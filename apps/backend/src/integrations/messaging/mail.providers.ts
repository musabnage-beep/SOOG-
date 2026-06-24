import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SendEmailCommand, SESClient } from '@aws-sdk/client-ses';
import { MailMessage, MailProvider } from './messaging.interface';

/** Dev mail provider: logs the email. */
@Injectable()
export class ConsoleMailProvider implements MailProvider {
  private readonly logger = new Logger('MAIL');

  async send(message: MailMessage): Promise<void> {
    this.logger.log(`[DEV-MAIL] to=${message.to} subject="${message.subject}"`);
  }
}

/** Production mail provider via AWS SES. */
@Injectable()
export class SesMailProvider implements MailProvider {
  private readonly client: SESClient;
  private readonly from: string;

  constructor(config: ConfigService) {
    this.from = config.getOrThrow<string>('MAIL_FROM');
    this.client = new SESClient({
      region: config.get<string>('SES_REGION', config.get<string>('AWS_REGION', 'me-central-1')),
      credentials: {
        accessKeyId: config.getOrThrow<string>('AWS_ACCESS_KEY_ID'),
        secretAccessKey: config.getOrThrow<string>('AWS_SECRET_ACCESS_KEY'),
      },
    });
  }

  async send(message: MailMessage): Promise<void> {
    await this.client.send(
      new SendEmailCommand({
        Source: this.from,
        Destination: { ToAddresses: [message.to] },
        Message: {
          Subject: { Data: message.subject, Charset: 'UTF-8' },
          Body: {
            Html: { Data: message.html, Charset: 'UTF-8' },
            ...(message.text ? { Text: { Data: message.text, Charset: 'UTF-8' } } : {}),
          },
        },
      }),
    );
  }
}
