'use client';

import type { ReactNode } from 'react';
import { AuthProvider, QueryProvider } from '@aldiafa/shared/client';
import { ToastProvider } from '@aldiafa/shared/ui';
import { API_URL, COOKIE_PREFIX } from '@/lib/config';

export function Providers({ children }: { children: ReactNode }) {
  return (
    <QueryProvider>
      <AuthProvider baseUrl={API_URL} allowedRoles={['ADMIN']} cookiePrefix={COOKIE_PREFIX}>
        <ToastProvider>{children}</ToastProvider>
      </AuthProvider>
    </QueryProvider>
  );
}
