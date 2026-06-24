'use client';

import type { ReactNode } from 'react';
import { Card } from './primitives';
import { cn } from './cn';

export function StatCard({
  label,
  value,
  icon,
  tone = 'bg-brand/10 text-brand',
  hint,
}: {
  label: string;
  value: ReactNode;
  icon?: ReactNode;
  tone?: string;
  hint?: string;
}) {
  return (
    <Card className="p-5">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-sm text-gray-500">{label}</p>
          <p className="mt-1 truncate text-2xl font-bold text-gray-900">{value}</p>
          {hint && <p className="mt-1 text-xs text-gray-400">{hint}</p>}
        </div>
        {icon && (
          <div className={cn('flex h-11 w-11 shrink-0 items-center justify-center rounded-xl', tone)}>
            {icon}
          </div>
        )}
      </div>
    </Card>
  );
}
