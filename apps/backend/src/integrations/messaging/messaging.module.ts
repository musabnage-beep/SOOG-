import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MAIL_PROVIDER, PUSH_PROVIDER, SMS_PROVIDER } from './messaging.interface';
import { ConsoleSmsProvider, MsegatSmsProvider, TwilioSmsProvider, UnifonicSmsProvider } from './sms.providers';
import { ConsolePushProvider, FcmPushProvider } from './push.providers';
import { ConsoleMailProvider, SesMailProvider } from './mail.providers';

@Global()
@Module({
  providers: [
    {
      provide: SMS_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const p = config.get('SMS_PROVIDER');
        if (p === 'unifonic') return new UnifonicSmsProvider(config);
        if (p === 'msegat') return new MsegatSmsProvider(config);
        if (p === 'twilio') return new TwilioSmsProvider(config);
        return new ConsoleSmsProvider();
      },
    },
    {
      provide: PUSH_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        config.get('PUSH_PROVIDER') === 'fcm'
          ? new FcmPushProvider(config)
          : new ConsolePushProvider(),
    },
    {
      provide: MAIL_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        config.get('MAIL_PROVIDER') === 'ses'
          ? new SesMailProvider(config)
          : new ConsoleMailProvider(),
    },
  ],
  exports: [SMS_PROVIDER, PUSH_PROVIDER, MAIL_PROVIDER],
})
export class MessagingModule {}
