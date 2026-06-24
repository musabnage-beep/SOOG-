'use client';

import type { ReactNode } from 'react';
import { AlertCircle, Inbox } from 'lucide-react';
import { Spinner, Button } from './primitives';
import { cn } from './cn';

export function Loading({ className, label }: { className?: string; label?: string }) {
  return (
    <div className={cn('flex flex-col items-center justify-center gap-3 py-16', className)}>
      <Spinner className="h-7 w-7" />
      {label && <p className="text-sm text-gray-500">{label}</p>}
    </div>
  );
}

export function ErrorState({
  message,
  onRetry,
  className,
}: {
  message?: string;
  onRetry?: () => void;
  className?: string;
}) {
  return (
    <div className={cn('flex flex-col items-center justify-center gap-3 py-16 text-center', className)}>
      <AlertCircle className="h-10 w-10 text-red-500" />
      <p className="text-sm text-gray-600">{message ?? 'حدث خطأ أثناء تحميل البيانات'}</p>
      {onRetry && (
        <Button variant="outline" size="sm" onClick={onRetry}>
          إعادة المحاولة
        </Button>
      )}
    </div>
  );
}

export function EmptyState({
  title,
  subtitle,
  icon,
  action,
  className,
}: {
  title: string;
  subtitle?: string;
  icon?: ReactNode;
  action?: ReactNode;
  className?: string;
}) {
  return (
    <div className={cn('flex flex-col items-center justify-center gap-2 py-16 text-center', className)}>
      <div className="mb-1 text-gray-300">{icon ?? <Inbox className="h-12 w-12" />}</div>
      <p className="text-base font-semibold text-gray-800">{title}</p>
      {subtitle && <p className="max-w-sm text-sm text-gray-500">{subtitle}</p>}
      {action && <div className="mt-3">{action}</div>}
    </div>
  );
}
