export const MAPS_PROVIDER = Symbol('MAPS_PROVIDER');

export interface LatLng {
  latitude: number;
  longitude: number;
}

export interface DistanceResult {
  distanceMeters: number;
  durationSeconds: number;
}

export interface MapsProvider {
  /** Real road distance + duration between two points. */
  distance(origin: LatLng, destination: LatLng): Promise<DistanceResult>;
}
