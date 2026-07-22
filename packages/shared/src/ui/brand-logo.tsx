'use client';

import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react';

const GOLD = '#D4AF37';

/**
 * ALDIAFAH brand mark — a sweeping swoosh arc with a gold inner stroke and
 * three descending gold dots. Rendered as inline SVG so it stays crisp at any
 * size and inherits its arc color from `currentColor`.
 */
export function BrandMark({ size = 40, className }: { size?: number; className?: string }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 64 64"
      fill="none"
      className={className}
      aria-hidden="true"
    >
      <path
        d="M6 30 Q32 4 58 28"
        stroke="currentColor"
        strokeWidth={5}
        strokeLinecap="round"
      />
      <path d="M16 28 Q32 16 48 26" stroke={GOLD} strokeWidth={3} strokeLinecap="round" />
      <circle cx={14} cy={40} r={3} fill={GOLD} />
      <circle cx={11} cy={48} r={2.5} fill={GOLD} />
      <circle cx={8} cy={55} r={2} fill={GOLD} />
    </svg>
  );
}

/**
 * The real logo image (`/logo/logo-white.png` on dark, `/logo/logo-color.png`
 * on light). Renders `fallback` if the file is missing, so a dashboard without
 * the asset still shows the vector interpretation. Each app serves the file
 * from its own `public/logo/` folder.
 */
export function BrandImage({
  onDark = false,
  fallback,
  className,
  style,
}: {
  onDark?: boolean;
  fallback: ReactNode;
  className?: string;
  style?: CSSProperties;
}) {
  const [failed, setFailed] = useState(false);
  const ref = useRef<HTMLImageElement>(null);

  // Catch a 404 that resolves before hydration attaches the onError handler.
  useEffect(() => {
    const img = ref.current;
    if (img && img.complete && img.naturalWidth === 0) setFailed(true);
  }, []);

  if (failed) return <>{fallback}</>;
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      ref={ref}
      src={onDark ? '/logo/logo-white.png' : '/logo/logo-color.png'}
      alt="الضيافة"
      className={className}
      style={style}
      onError={() => setFailed(true)}
    />
  );
}

/**
 * Full brand lockup: prefers the real logo image; falls back to the mark above
 * the Arabic logotype "الضيافة" and the latin "ALDIAFAH". Use `onDark` on dark
 * backgrounds.
 */
export function BrandLogo({
  size = 120,
  onDark = false,
  showLatin = true,
  className,
}: {
  size?: number;
  onDark?: boolean;
  showLatin?: boolean;
  className?: string;
}) {
  const wordStyle: CSSProperties = {
    fontSize: size * 0.3,
    lineHeight: 1,
    fontWeight: 900,
    letterSpacing: '-0.02em',
    color: onDark ? '#FFFFFF' : '#111827',
  };
  const fallback = (
    <div className={className} style={{ display: 'inline-flex', flexDirection: 'column', alignItems: 'center', gap: size * 0.05 }}>
      <BrandMark size={size * 0.55} className={onDark ? 'text-white' : 'text-brand'} />
      <span dir="rtl" style={wordStyle}>
        الضيافة
      </span>
      {showLatin && (
        <span
          style={{
            fontSize: size * 0.09,
            fontWeight: 700,
            letterSpacing: `${size * 0.03}px`,
            color: GOLD,
          }}
        >
          ALDIAFAH
        </span>
      )}
    </div>
  );
  return <BrandImage onDark={onDark} fallback={fallback} className={className} style={{ width: size, height: 'auto' }} />;
}
