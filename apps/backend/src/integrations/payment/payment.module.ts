import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PAYMENT_PROVIDER } from './payment.interface';
import { ConsolePaymentProvider, MoyasarPaymentProvider } from './payment.providers';

@Global()
@Module({
  providers: [
    {
      provide: PAYMENT_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        config.get('PAYMENT_PROVIDER') === 'moyasar'
          ? new MoyasarPaymentProvider(config)
          : new ConsolePaymentProvider(),
    },
  ],
  exports: [PAYMENT_PROVIDER],
})
export class PaymentModule {}
