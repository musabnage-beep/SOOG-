'use client';

import { useEffect, useRef, useState } from 'react';

/**
 * Renders an <img> from the public assets folder. If the file does not exist
 * yet it hides itself (no broken-image glyph, no substitute icon or emoji),
 * leaving the parent's reserved space empty. Dropping the real file with the
 * matching name makes it appear automatically — no code change required.
 */
export function SafeImage({
  src,
  alt,
  className,
}: {
  src: string;
  alt: string;
  className?: string;
}) {
  const [failed, setFailed] = useState(false);
  const ref = useRef<HTMLImageElement>(null);

  // Catch a 404 that resolves before hydration attaches the onError handler.
  useEffect(() => {
    const img = ref.current;
    if (img && img.complete && img.naturalWidth === 0) setFailed(true);
  }, []);

  if (failed) return null;
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      ref={ref}
      src={src}
      alt={alt}
      className={className}
      onError={() => setFailed(true)}
    />
  );
}
