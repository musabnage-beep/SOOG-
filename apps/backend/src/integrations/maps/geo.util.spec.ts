import { haversineMeters, isValidCoordinate } from './geo.util';

describe('haversineMeters', () => {
  it('returns zero for identical points', () => {
    const p = { latitude: 24.7136, longitude: 46.6753 };
    expect(haversineMeters(p, p)).toBe(0);
  });

  it('computes a known Riyadh→Jeddah distance within tolerance', () => {
    const riyadh = { latitude: 24.7136, longitude: 46.6753 };
    const jeddah = { latitude: 21.4858, longitude: 39.1925 };
    const meters = haversineMeters(riyadh, jeddah);
    // Real great-circle distance is ~847 km; allow 1% tolerance.
    expect(meters).toBeGreaterThan(838_000);
    expect(meters).toBeLessThan(856_000);
  });

  it('is symmetric', () => {
    const a = { latitude: 24.7, longitude: 46.6 };
    const b = { latitude: 24.8, longitude: 46.7 };
    expect(haversineMeters(a, b)).toBe(haversineMeters(b, a));
  });
});

describe('isValidCoordinate', () => {
  it('accepts valid Saudi coordinates', () => {
    expect(isValidCoordinate(24.7136, 46.6753)).toBe(true);
  });

  it('rejects out-of-range values', () => {
    expect(isValidCoordinate(91, 0)).toBe(false);
    expect(isValidCoordinate(0, 181)).toBe(false);
    expect(isValidCoordinate(-91, 0)).toBe(false);
  });

  it('rejects non-finite values', () => {
    expect(isValidCoordinate(NaN, 46)).toBe(false);
    expect(isValidCoordinate(24, Infinity)).toBe(false);
  });

  it('rejects null island (0,0)', () => {
    expect(isValidCoordinate(0, 0)).toBe(false);
  });
});
