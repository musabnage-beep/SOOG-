'use client';

import Link from 'next/link';
import { IconSearch, IconAccount, IconCart } from './icons';
import { BrandLockup } from './brand-lockup';

const NAV = [
  { label: 'الرئيسية', href: '/' },
  { label: 'المنتجات', href: '/#products' },
  { label: 'من نحن', href: '/about' },
  { label: 'تواصل معنا', href: '/contact' },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 bg-brand-dark text-white">
      <div className="mx-auto flex h-16 max-w-7xl items-center gap-6 px-6">
        {/* Logo (right in RTL) */}
        <Link href="/" className="shrink-0">
          <BrandLockup height={46} />
        </Link>

        {/* Search */}
        <div className="flex min-w-0 flex-1 justify-center">
          <div className="flex h-11 w-full max-w-[440px] items-center gap-2 rounded-full bg-white/95 px-4 text-gray-500 shadow-sm">
            <IconSearch size={16} className="shrink-0" />
            <input
              type="text"
              placeholder="ابحث عن متجر..."
              className="min-w-0 flex-1 bg-transparent text-sm text-gray-700 placeholder:text-gray-400 outline-none"
            />
          </div>
        </div>

        {/* Nav */}
        <nav className="hidden items-center gap-6 lg:flex">
          {NAV.map((item, i) => (
            <Link
              key={item.href}
              href={item.href}
              className={`whitespace-nowrap text-[15px] transition-colors hover:text-brand-goldLight ${
                i === 0 ? 'font-bold text-white' : 'text-white/85'
              }`}
            >
              {item.label}
            </Link>
          ))}
        </nav>

        {/* Actions (left in RTL) */}
        <div className="flex shrink-0 items-center gap-3">
          <button
            aria-label="حسابي"
            className="flex h-10 w-10 items-center justify-center rounded-full border border-white/25 text-white/90 transition-colors hover:bg-white/10"
          >
            <IconAccount size={20} />
          </button>
          <button
            aria-label="السلة"
            className="relative flex h-10 w-10 items-center justify-center rounded-full bg-brand text-white transition-colors hover:bg-brand-light"
          >
            <IconCart size={20} />
            <span className="absolute -right-1 -top-1 flex h-5 min-w-5 items-center justify-center rounded-full bg-brand-gold px-1 text-[11px] font-bold text-brand-dark">
              0
            </span>
          </button>
        </div>
      </div>
    </header>
  );
}
