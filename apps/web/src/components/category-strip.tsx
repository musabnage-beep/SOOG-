import Link from 'next/link';
import type { Category } from '@/lib/catalog';
import { IconAllCategories } from './icons';
import { SafeImage } from './safe-image';

/**
 * Maps a backend category slug to its spec category-icon filename.
 * Slugs not listed fall back to the slug itself, so dropping a file named
 * `<slug>.png` into public/category-icons always works with no code change.
 */
const ICON_FILE: Record<string, string> = {
  'canned-goods': 'canned-food',
  'spices-herbs': 'spices',
  'soft-drinks': 'beverages',
  'dairy-eggs': 'dairy',
  noodles: 'pasta',
  frozen: 'frozen-food',
  'plastics-cleaning': 'cleaning',
  'rice-grains': 'rice',
};

function Tile({
  href,
  label,
  children,
}: {
  href: string;
  label: string;
  children: React.ReactNode;
}) {
  return (
    <Link href={href} className="flex w-[76px] shrink-0 flex-col items-center gap-2">
      <div className="flex h-[68px] w-[68px] items-center justify-center overflow-hidden rounded-2xl bg-brand-cream ring-1 ring-black/5 transition-transform hover:-translate-y-0.5">
        {children}
      </div>
      <span className="line-clamp-1 text-center text-[12px] font-medium text-gray-700">
        {label}
      </span>
    </Link>
  );
}

export function CategoryStrip({ categories }: { categories: Category[] }) {
  return (
    <section className="mx-auto max-w-7xl px-6 py-6">
      <div className="no-scrollbar flex items-start gap-4 overflow-x-auto">
        <Tile href="/#products" label="عرض جميع الأقسام">
          <IconAllCategories size={28} className="text-brand" />
        </Tile>
        {categories.map((c) => (
          <Tile key={c.slug} href="/#products" label={c.nameAr}>
            <SafeImage
              src={`/category-icons/${ICON_FILE[c.slug] ?? c.slug}.png`}
              alt={c.nameAr}
              className="h-[52px] w-[52px] object-contain"
            />
          </Tile>
        ))}
      </div>
    </section>
  );
}
