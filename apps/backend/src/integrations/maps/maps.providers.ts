import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DistanceResult, LatLng, MapsProvider } from './maps.interface';
import { haversineMeters } from './geo.util';

/**
 * Dev maps provider: computes straight-line distance (haversine) and estimates
 * duration from a configurable average speed. No external network calls.
 */
@Injectable()
export class DevMapsProvider implements MapsProvider {
  private readonly avgSpeedKmh: number;

  constructor(config: ConfigService) {
    this.avgSpeedKmh = config.get<number>('DEV_AVG_SPEED_KMH', 30);
  }

  async distance(origin: LatLng, destination: LatLng): Promise<DistanceResult> {
    // Inflate straight-line distance by ~1.3x to approximate road distance.
    const straight = haversineMeters(origin, destination);
    const distanceMeters = Math.round(straight * 1.3);
    const speedMs = (this.avgSpeedKmh * 1000) / 3600;
    return { distanceMeters, durationSeconds: Math.round(distanceMeters / speedMs) };
  }
}

/** Production maps provider via Google Distance Matrix API. */
@Injectable()
export class GoogleMapsProvider implements MapsProvider {
  private readonly logger = new Logger('MAPS');
  private readonly apiKey: string;

  constructor(config: ConfigService) {
    this.apiKey = config.getOrThrow<string>('GOOGLE_MAPS_API_KEY');
  }

  async distance(origin: LatLng, destination: LatLng): Promise<DistanceResult> {
    const url = new URL('https://maps.googleapis.com/maps/api/distancematrix/json');
    url.searchParams.set('origins', `${origin.latitude},${origin.longitude}`);
    url.searchParams.set('destinations', `${destination.latitude},${destination.longitude}`);
    url.searchParams.set('mode', 'driving');
    url.searchParams.set('key', this.apiKey);

    const res = await fetch(url.toString());
    const json = (await res.json()) as {
      rows?: { elements?: { status: string; distance?: { value: number }; duration?: { value: number } }[] }[];
    };
    const el = json.rows?.[0]?.elements?.[0];
    if (!el || el.status !== 'OK' || !el.distance || !el.duration) {
      this.logger.error(`Google Distance Matrix returned ${el?.status ?? 'no element'}`);
      // Fallback to haversine so checkout is never blocked by a transient maps error.
      const straight = haversineMeters(origin, destination);
      return { distanceMeters: Math.round(straight * 1.3), durationSeconds: Math.round((straight * 1.3) / 8.3) };
    }
    return { distanceMeters: el.distance.value, durationSeconds: el.duration.value };
  }
}
