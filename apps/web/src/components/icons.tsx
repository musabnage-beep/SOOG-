/**
 * Custom line-icon library for the storefront, matching the ALDIAFAH asset
 * spec: 2px stroke, rounded caps/joins, 24x24 grid, drawn with `currentColor`
 * so each icon inherits colour from its context (gold, white, green, …).
 *
 * These are the authored SVGs — the `public/icons/**` folders hold the same
 * marks as standalone files that designers can swap without touching code.
 */
import type { SVGProps } from 'react';

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function Svg({ size = 24, children, ...props }: IconProps & { children: React.ReactNode }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      {...props}
    >
      {children}
    </svg>
  );
}

/* ── navigation ─────────────────────────────────────────── */

export function IconHome(p: IconProps) {
  return (
    <Svg {...p}>
      <path d="M3 10.5 12 3l9 7.5" />
      <path d="M5 9.5V20a1 1 0 0 0 1 1h4v-6h4v6h4a1 1 0 0 0 1-1V9.5" />
    </Svg>
  );
}

export function IconCategories(p: IconProps) {
  return (
    <Svg {...p}>
      <rect x="3" y="3" width="7" height="7" rx="1.5" />
      <rect x="14" y="3" width="7" height="7" rx="1.5" />
      <rect x="3" y="14" width="7" height="7" rx="1.5" />
      <rect x="14" y="14" width="7" height="7" rx="1.5" />
    </Svg>
  );
}

export function IconCart(p: IconProps) {
  return (
    <Svg {...p}>
      <path d="M3 4h2l2.2 11.2a1.5 1.5 0 0 0 1.5 1.2h8.1a1.5 1.5 0 0 0 1.5-1.2L21 7H6" />
      <circle cx="9.5" cy="20" r="1.4" />
      <circle cx="17.5" cy="20" r="1.4" />
    </Svg>
  );
}

export function IconOrders(p: IconProps) {
  return (
    <Svg {...p}>
      <path d="M8 3h8a1 1 0 0 1 1 1v1h1a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h1V4a1 1 0 0 1 1-1Z" />
      <path d="M8 4v2h8V4" />
      <path d="M8.5 11h7M8.5 15h4" />
    </Svg>
  );
}

export function IconFavorites(p: IconProps) {
  return (
    <Svg {...p}>
      <path d="M12 20.5 4.6 13a4.6 4.6 0 0 1 6.5-6.5l.9.9.9-.9A4.6 4.6 0 0 1 19.4 13Z" />
    </Svg>
  );
}

export function IconAccount(p: IconProps) {
  return (
    <Svg {...p}>
      <circle cx="12" cy="8" r="4" />
      <path d="M4 20a8 8 0 0 1 16 0" />
    </Svg>
  );
}

export function IconSupport(p: IconProps) {
  return (
    <Svg {...p}>
      <path d="M4 13v-1a8 8 0 0 1 16 0v1" />
      <rect x="3" y="13" width="4" height="6" rx="1.5" />
      <rect x="17" y="13" width="4" height="6" rx="1.5" />
      <path d="M20 19a4 4 0 0 1-4 3h-2" />
    </Svg>
  );
}

/* ── action ─────────────────────────────────────────────── */

export function IconSearch(p: IconProps) {
  return (
    <Svg {...p}>
      <circle cx="11" cy="11" r="7" />
      <path d="m20 20-3.2-3.2" />
    </Svg>
  );
}

export function IconArrowLeft(p: IconProps) {
  return (
    <Svg {...p}>
      <path d="M19 12H5" />
      <path d="m11 6-6 6 6 6" />
    </Svg>
  );
}

export function IconArrowRight(p: IconProps) {
  return (
    <Svg {...p}>
      <path d="M5 12h14" />
      <path d="m13 6 6 6-6 6" />
    </Svg>
  );
}

/* ── service (features bar) ─────────────────────────────── */

export function IconFastDelivery(p: IconProps) {
  return (
    <Svg {...p}>
      <path d="M3 7h9v8H3z" />
      <path d="M12 10h4l3 3v2h-7z" />
      <circle cx="7" cy="18" r="1.6" />
      <circle cx="16.5" cy="18" r="1.6" />
      <path d="M1.5 9h4M1 12h3" />
    </Svg>
  );
}

export function IconSecurePayment(p: IconProps) {
  return (
    <Svg {...p}>
      <path d="M12 3 5 5.5V11c0 4.4 3 7.6 7 9 4-1.4 7-4.6 7-9V5.5Z" />
      <path d="m9 12 2 2 4-4" />
    </Svg>
  );
}

export function IconHighQuality(p: IconProps) {
  return (
    <Svg {...p}>
      <circle cx="12" cy="9" r="6" />
      <path d="m9 8.5 2 2 4-4" />
      <path d="m8 14-2 7 6-3 6 3-2-7" />
    </Svg>
  );
}

export function IconSupport247(p: IconProps) {
  return (
    <Svg {...p}>
      <path d="M4 13v-1a8 8 0 0 1 16 0v1" />
      <rect x="3" y="13" width="4" height="6" rx="1.5" />
      <rect x="17" y="13" width="4" height="6" rx="1.5" />
    </Svg>
  );
}

export function IconEasyReturn(p: IconProps) {
  return (
    <Svg {...p}>
      <path d="M4 9a8 8 0 0 1 14-3l2 2" />
      <path d="M20 4v4h-4" />
      <path d="M20 15a8 8 0 0 1-14 3l-2-2" />
      <path d="M4 20v-4h4" />
    </Svg>
  );
}

export function IconExclusiveOffers(p: IconProps) {
  return (
    <Svg {...p}>
      <path d="M4 4h7.5a2 2 0 0 1 1.4.6l6.5 6.5a2 2 0 0 1 0 2.8l-5.6 5.6a2 2 0 0 1-2.8 0L4.6 13A2 2 0 0 1 4 11.5Z" />
      <circle cx="8.5" cy="8.5" r="1.3" />
    </Svg>
  );
}

export function IconAllCategories(p: IconProps) {
  return (
    <Svg {...p}>
      <rect x="3" y="3" width="7" height="7" rx="1.5" />
      <rect x="14" y="3" width="7" height="7" rx="1.5" />
      <rect x="3" y="14" width="7" height="7" rx="1.5" />
      <rect x="14" y="14" width="7" height="7" rx="1.5" />
    </Svg>
  );
}
