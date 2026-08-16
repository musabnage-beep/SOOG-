import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const monorepoRoot = join(dirname(fileURLToPath(import.meta.url)), '..', '..');

const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000/api';
const apiOrigin = new URL(apiUrl).origin;

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'standalone',
  outputFileTracingRoot: monorepoRoot,
  transpilePackages: ['@aldiafa/shared'],
  /**
   * The API serves uploaded images over plain HTTP. A browser blocks those on
   * an HTTPS page, so they are proxied through this same-origin path and reach
   * the browser over the site's own TLS instead.
   */
  async rewrites() {
    return [{ source: '/media/:path*', destination: `${apiOrigin}/:path*` }];
  },
  images: {
    remotePatterns: [
      { protocol: 'http', hostname: 'localhost' },
      { protocol: 'http', hostname: '18.194.190.26' },
      { protocol: 'https', hostname: '**' },
    ],
  },
};

export default nextConfig;
