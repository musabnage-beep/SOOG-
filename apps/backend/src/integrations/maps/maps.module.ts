import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MAPS_PROVIDER } from './maps.interface';
import { DevMapsProvider, GoogleMapsProvider } from './maps.providers';

@Global()
@Module({
  providers: [
    {
      provide: MAPS_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        config.get('MAPS_PROVIDER') === 'google'
          ? new GoogleMapsProvider(config)
          : new DevMapsProvider(config),
    },
  ],
  exports: [MAPS_PROVIDER],
})
export class MapsModule {}
