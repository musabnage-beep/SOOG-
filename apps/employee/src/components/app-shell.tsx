'use client';

import type { ReactNode } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { DashboardShell, RequireAuth, useUnreadCount } from '@aldiafa/shared/client';
import { NAV, LOGIN_PATH } from '@/lib/config';

export function AppShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { data: unread } = useUnreadCount();

  return (
    <RequireAuth loginPath={LOGIN_PATH} redirect={(p) => router.replace(p)}>
      <DashboardShell
        brand="الضيافة"
        subtitle="لوحة الموظفين"
        nav={NAV}
        pathname={pathname}
        Link={Link}
        unreadCount={unread?.count}
        notificationsHref="/notifications"
      >
        {children}
      </DashboardShell>
    </RequireAuth>
  );
}
