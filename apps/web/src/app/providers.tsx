'use client';

import type { ReactNode } from 'react';
import { QueryProvider } from '@aldiafa/shared/client';
import { ToastProvider } from '@aldiafa/shared/ui';

export function Providers({ children }: { children: ReactNode }) {
  return (
    <QueryProvider>
      <ToastProvider>{children}</ToastProvider>
    </QueryProvider>
  );
}
