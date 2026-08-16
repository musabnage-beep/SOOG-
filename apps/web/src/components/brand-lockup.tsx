'use client';

import { useEffect, useRef, useState } from 'react';

const GOLD = '#CFA347';
const GOLD_LIGHT = '#FFD979';

/** Compact swoosh + 3 descending dots mark. */
function Mark({ size = 30 }: { size?: number }) {
  return (
    <svg width={size} height={size * 0.62} viewBox="0 0 64 40" fill="none" aria-hidden="true">
      <path d="M6 26 Q32 -2 58 24" stroke="#FFFFFF" strokeWidth={4.5} strokeLinecap="round" />
      <path d="M16 24 Q32 12 48 22" stroke={GOLD} strokeWidth={3} strokeLinecap="round" />
      <circle cx={13} cy={31} r={2.6} fill={GOLD} />
      <circle cx={10} cy={37} r={2.1} fill={GOLD} />
    </svg>
  );
}

/**
 * Header brand lockup. Prefers the real logo file
 * (`/logo/logo-white.png`, the white variant for the dark header); until it
 * is dropped in, renders the vector interpretation. Swapping the file needs
 * no code change.
 */
export function BrandLockup({ height = 44 }: { height?: number }) {
  const [failed, setFailed] = useState(false);
  const ref = useRef<HTMLImageElement>(null);

  // Catch a 404 that resolves before hydration attaches the onError handler.
  useEffect(() => {
    const img = ref.current;
    if (img && img.complete && img.naturalWidth === 0) setFailed(true);
  }, []);

  if (!failed) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        ref={ref}
        src="/logo/logo-white.png"
        alt="الضيافة"
        style={{ height }}
        onError={() => setFailed(true)}
      />
    );
  }
  return (
    <div className="flex flex-col items-center leading-none" style={{ height }}>
      <Mark size={height * 0.62} />
      <span
        dir="rtl"
        style={{
          fontSize: height * 0.42,
          fontWeight: 900,
          background: `linear-gradient(90deg, ${GOLD_LIGHT}, ${GOLD})`,
          WebkitBackgroundClip: 'text',
          backgroundClip: 'text',
          color: 'transparent',
          marginTop: height * 0.04,
        }}
      >
        الضيافة
      </span>
    </div>
  );
}
