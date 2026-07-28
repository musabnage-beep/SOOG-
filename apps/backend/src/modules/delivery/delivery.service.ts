import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import sharp from 'sharp';
import { PrismaService } from '@/prisma/prisma.service';
import { SettingsService } from '@/modules/settings/settings.service';
import { MAPS_PROVIDER, MapsProvider } from '@/integrations/maps/maps.interface';
import { isValidCoordinate } from '@/integrations/maps/geo.util';
import { STORAGE_PROVIDER, StorageProvider } from '@/integrations/storage/storage.interface';
import { UpsertDeliveryProviderDto } from './dto/delivery.dto';

const LOGO_MIME = ['image/jpeg', 'image/png', 'image/webp'];
const LOGO_MAX_BYTES = 4 * 1024 * 1024;

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
    @Inject(STORAGE_PROVIDER) private readonly storage: StorageProvider,
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

  // ── Third-party delivery providers ────────────────────────────────────────

  listProviders(activeOnly: boolean) {
    return this.prisma.deliveryProvider.findMany({
      where: activeOnly ? { isActive: true } : undefined,
      orderBy: [{ deliveryFee: 'asc' }, { name: 'asc' }],
    });
  }

  createProvider(dto: UpsertDeliveryProviderDto) {
    return this.prisma.deliveryProvider.create({ data: dto });
  }

  async updateProvider(id: string, dto: UpsertDeliveryProviderDto) {
    await this.getProvider(id);
    return this.prisma.deliveryProvider.update({ where: { id }, data: dto });
  }

  async deleteProvider(id: string) {
    const provider = await this.getProvider(id);
    const linked = await this.prisma.order.count({ where: { deliveryProviderId: id } });
    if (linked > 0) {
      throw new BadRequestException(
        'لا يمكن حذف شركة مرتبطة بطلبات — قم بتعطيلها بدلاً من حذفها',
      );
    }
    if (provider.logoKey) await this.storage.delete(provider.logoKey);
    await this.prisma.deliveryProvider.delete({ where: { id } });
    return { ok: true };
  }

  async uploadProviderLogo(id: string, file?: Express.Multer.File) {
    const provider = await this.getProvider(id);
    if (!file) throw new BadRequestException('No file provided');
    if (!LOGO_MIME.includes(file.mimetype)) {
      throw new BadRequestException(`Unsupported type: ${file.mimetype}`);
    }
    if (file.size > LOGO_MAX_BYTES) throw new BadRequestException('File too large (max 4MB)');

    const webp = await sharp(file.buffer)
      .resize(512, 512, { fit: 'inside', withoutEnlargement: true })
      .webp({ quality: 88 })
      .toBuffer();

    const stored = await this.storage.upload({
      buffer: webp,
      contentType: 'image/webp',
      key: `delivery-providers/${id}/${Date.now()}.webp`,
    });

    if (provider.logoKey) await this.storage.delete(provider.logoKey);
    return this.prisma.deliveryProvider.update({
      where: { id },
      data: { logo: stored.url, logoKey: stored.key },
    });
  }

  private async getProvider(id: string) {
    const provider = await this.prisma.deliveryProvider.findUnique({ where: { id } });
    if (!provider) throw new NotFoundException('Delivery provider not found');
    return provider;
  }
}
