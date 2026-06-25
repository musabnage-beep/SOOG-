'use client';

import { useState, type ComponentType, type ReactNode } from 'react';
import { LogOut, Menu, X, Bell } from 'lucide-react';
import { cn } from '../ui/cn';
import { BrandMark } from '../ui/brand-logo';
import { useAuth } from './auth';
import { ROLE_LABEL_AR } from '../constants';

export interface NavItem {
  href: string;
  label: string;
  icon: ComponentType<{ className?: string }>;
}

type LinkLike = (props: {
  href: string;
  className?: string;
  children: ReactNode;
  onClick?: () => void;
}) => ReactNode;

export function DashboardShell({
  brand,
  subtitle,
  nav,
  pathname,
  Link,
  unreadCount,
  notificationsHref,
  children,
}: {
  brand: string;
  subtitle?: string;
  nav: NavItem[];
  pathname: string;
  Link: LinkLike;
  unreadCount?: number;
  notificationsHref?: string;
  children: ReactNode;
}) {
  const { user, logout } = useAuth();
  const [open, setOpen] = useState(false);

  const isActive = (href: string) =>
    href === '/' ? pathname === '/' : pathname === href || pathname.startsWith(`${href}/`);

  const sidebar = (
    <div className="flex h-full flex-col">
      <div className="flex items-center gap-3 border-b border-white/10 px-5 py-5">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-brand-gold text-brand-dark">
          <BrandMark size={26} />
        </div>
        <div>
          <p className="text-base font-bold text-white">{brand}</p>
          {subtitle && <p className="text-xs text-white/60">{subtitle}</p>}
        </div>
      </div>
      <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4">
        {nav.map((item) => {
          const Icon = item.icon;
          const active = isActive(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={() => setOpen(false)}
              className={cn(
                'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
                active ? 'bg-white/15 text-white' : 'text-white/70 hover:bg-white/10 hover:text-white',
              )}
            >
              <Icon className="h-5 w-5 shrink-0" />
              {item.label}
            </Link>
          );
        })}
      </nav>
      <div className="border-t border-white/10 p-3">
        <button
          onClick={() => logout()}
          className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-white/70 transition-colors hover:bg-white/10 hover:text-white"
        >
          <LogOut className="h-5 w-5" />
          تسجيل الخروج
        </button>
      </div>
    </div>
  );

  return (
    <div className="flex min-h-screen bg-gray-50" dir="rtl">
      {/* desktop sidebar */}
      <aside className="hidden w-64 shrink-0 bg-brand-dark lg:block">{sidebar}</aside>

      {/* mobile drawer */}
      {open && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <div className="absolute inset-0 bg-black/40" onClick={() => setOpen(false)} />
          <aside className="absolute right-0 top-0 h-full w-64 bg-brand-dark">{sidebar}</aside>
        </div>
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-gray-200 bg-white px-4 lg:px-6">
          <button
            className="rounded-lg p-2 text-gray-600 hover:bg-gray-100 lg:hidden"
            onClick={() => setOpen((v) => !v)}
          >
            {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
          <div className="flex flex-1 items-center justify-end gap-4">
            {notificationsHref && (
              <Link href={notificationsHref} className="relative rounded-lg p-2 text-gray-600 hover:bg-gray-100">
                <Bell className="h-5 w-5" />
                {!!unreadCount && unreadCount > 0 && (
                  <span className="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
                    {unreadCount > 99 ? '99+' : unreadCount}
                  </span>
                )}
              </Link>
            )}
            <div className="flex items-center gap-3">
              <div className="text-left">
                <p className="text-sm font-semibold text-gray-900">{user?.fullName}</p>
                <p className="text-xs text-gray-500">{user ? ROLE_LABEL_AR[user.role] : ''}</p>
              </div>
              <div className="flex h-9 w-9 items-center justify-center rounded-full bg-brand/10 text-sm font-bold text-brand">
                {user?.fullName?.charAt(0) ?? '؟'}
              </div>
            </div>
          </div>
        </header>
        <main className="flex-1 p-4 lg:p-6">{children}</main>
      </div>
    </div>
  );
}
