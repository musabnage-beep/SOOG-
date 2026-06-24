import { BadRequestException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '@/prisma/prisma.service';
import { SettingsService } from '@/modules/settings/settings.service';
import { MAPS_PROVIDER, MapsProvider } from '@/integrations/maps/maps.interface';
import { DeliveryService } from './delivery.service';

const SETTINGS = {
  storeLatitude: 24.7136,
  storeLongitude: 46.6753,
  freeDeliveryRadiusM: 3000,
  deliveryRadiusM: 15000,
  baseDeliveryFee: 15,
  currency: 'SAR',
};

describe('DeliveryService', () => {
  let service: DeliveryService;
  let maps: jest.Mocked<MapsProvider>;
  let zoneFindFirst: jest.Mock;

  beforeEach(async () => {
    maps = { distance: jest.fn() };
    zoneFindFirst = jest.fn();
    const moduleRef = await Test.createTestingModule({
      providers: [
        DeliveryService,
        { provide: PrismaService, useValue: { deliveryZone: { findFirst: zoneFindFirst } } },
        { provide: SettingsService, useValue: { get: jest.fn().mockResolvedValue(SETTINGS) } },
        { provide: MAPS_PROVIDER, useValue: maps },
      ],
    }).compile();
    service = moduleRef.get(DeliveryService);
  });

  it('rejects invalid coordinates before hitting providers', async () => {
    await expect(service.quote(0, 0)).rejects.toBeInstanceOf(BadRequestException);
    expect(maps.distance).not.toHaveBeenCalled();
  });

  it('returns a free quote inside the free-delivery radius', async () => {
    maps.distance.mockResolvedValue({ distanceMeters: 1500, durationSeconds: 300 });
    const quote = await service.quote(24.72, 46.68);
    expect(quote.freeDelivery).toBe(true);
    expect(quote.withinRange).toBe(true);
    expect(quote.fee).toBe(0);
    expect(quote.etaMinutes).toBe(5);
    expect(zoneFindFirst).not.toHaveBeenCalled();
  });

  it('charges the matching zone fee beyond the free radius', async () => {
    maps.distance.mockResolvedValue({ distanceMeters: 6000, durationSeconds: 720 });
    zoneFindFirst.mockResolvedValue({ fee: 25 });
    const quote = await service.quote(24.8, 46.75);
    expect(quote.freeDelivery).toBe(false);
    expect(quote.withinRange).toBe(true);
    expect(quote.fee).toBe(25);
  });

  it('falls back to the base fee when no zone matches', async () => {
    maps.distance.mockResolvedValue({ distanceMeters: 6000, durationSeconds: 720 });
    zoneFindFirst.mockResolvedValue(null);
    const quote = await service.quote(24.8, 46.75);
    expect(quote.fee).toBe(SETTINGS.baseDeliveryFee);
  });

  it('reports out-of-range and charges no fee beyond the delivery radius', async () => {
    maps.distance.mockResolvedValue({ distanceMeters: 20000, durationSeconds: 1800 });
    const quote = await service.quote(25.0, 47.0);
    expect(quote.withinRange).toBe(false);
    expect(quote.fee).toBe(0);
    expect(zoneFindFirst).not.toHaveBeenCalled();
  });

  it('clamps ETA to at least one minute', async () => {
    maps.distance.mockResolvedValue({ distanceMeters: 50, durationSeconds: 10 });
    const quote = await service.quote(24.714, 46.676);
    expect(quote.etaMinutes).toBe(1);
  });
});
