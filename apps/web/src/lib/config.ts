export const API_URL =
  process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000/api';

/**
 * Origin the API (and its static uploads) is served from. Uploaded images come
 * back as absolute URLs on this origin, which is plain HTTP — browsers block
 * those on an HTTPS page, so they are rewritten onto the MEDIA_PREFIX proxy.
 */
export const API_ORIGIN = new URL(API_URL).origin;

/** Same-origin path that proxies through to API_ORIGIN (see next.config.mjs). */
export const MEDIA_PREFIX = '/media';

export const SITE_NAME = 'الضيافة';
