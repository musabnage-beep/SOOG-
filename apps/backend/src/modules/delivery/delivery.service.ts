import { BadRequestException, Inject, Injectable } from '@nestjs/common';
import { PrismaService } from '@/prisma/prisma.service';
import { SettingsService } from '@/modules/settings/settings.service';
import { MAPS_PROVIDER, MapsProvider } from '@/integrations/maps/maps.interface';
import { isValidCoordinate } from '@/integrations/maps/geo.util';

export interface DeliveryQuote {
  withinRange: boolean;
  freeDelivery: boolean;
  distanceMeters: number;
  etaMinutes: number;
  fee: number;
  currency: string;
}

@Injectable()
export class DeliveryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly settings: SettingsService,
    @Inject(MAPS_PROVIDER) private readonly maps: MapsProvider,
  ) {}

  /**
   * Calculates a delivery quote from configured store coordinates to a destination.
   * Always uses GPS coordinates + maps provider — never district names.
   */
  async quote(latitude: number, longitude: number): Promise<DeliveryQuote> {
    if (!isValidCoordinate(latitude, longitude)) {
      throw new BadRequestException('Invalid delivery coordinates');
    }

    const settings = await this.settings.get();
    const origin = { latitude: settings.storeLatitude, longitude: settings.storeLongitude };
    const { distanceMeters, durationSeconds } = await this.maps.distance(origin, {
      latitude,
      longitude,
    });

    const withinRange = distanceMeters <= settings.deliveryRadiusM;
    const freeDelivery = distanceMeters <= settings.freeDeliveryRadiusM;

    let fee = 0;
    if (!freeDelivery && withinRange) {
      const zone = await this.prisma.deliveryZone.findFirst({
        where: {
          isActive: true,
          minRadiusM: { lte: distanceMeters },
          maxRadiusM: { gte: distanceMeters },
        },
        orderBy: { minRadiusM: 'asc' },
      });
      fee = zone ? Number(zone.fee) : Number(settings.baseDeliveryFee);
    }

    return {
      withinRange,
      freeDelivery,
      distanceMeters,
      etaMinutes: Math.max(1, Math.round(durationSeconds / 60)),
      fee,
      currency: settings.currency,
    };
  }
}
