'use client';

import { CheckCheck, Bell } from 'lucide-react';
import { useNotifications, useNotificationActions } from '@aldiafa/shared/client';
import {
  Card,
  CardBody,
  Button,
  Loading,
  ErrorState,
  EmptyState,
  useToast,
} from '@aldiafa/shared/ui';
import { formatDateTime } from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

export default function NotificationsPage() {
  const { data, isLoading, isError, refetch } = useNotifications();
  const { markRead, markAllRead } = useNotificationActions();
  const toast = useToast();

  return (
    <div>
      <PageHeader
        title="الإشعارات"
        action={
          <Button
            variant="outline"
            loading={markAllRead.isPending}
            onClick={() =>
              markAllRead.mutateAsync().then(() => toast.success('تم تعليم الكل كمقروء'))
            }
          >
            <CheckCheck className="h-4 w-4" />
            تعليم الكل كمقروء
          </Button>
        }
      />

      <Card>
        <CardBody className="p-0">
          {isLoading ? (
            <Loading />
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : !data || data.length === 0 ? (
            <EmptyState title="لا توجد إشعارات" icon={<Bell className="h-12 w-12" />} />
          ) : (
            <ul className="divide-y divide-gray-100">
              {data.map((n) => (
                <li
                  key={n.id}
                  className={`flex cursor-pointer items-start gap-3 px-5 py-4 transition-colors hover:bg-gray-50 ${
                    n.isRead ? '' : 'bg-brand/5'
                  }`}
                  onClick={() => !n.isRead && markRead.mutate(n.id)}
                >
                  <div className={`mt-1.5 h-2 w-2 shrink-0 rounded-full ${n.isRead ? 'bg-transparent' : 'bg-brand'}`} />
                  <div className="min-w-0 flex-1">
                    <p className="font-medium text-gray-900">{n.title}</p>
                    <p className="text-sm text-gray-600">{n.body}</p>
                    <p className="mt-1 text-xs text-gray-400">{formatDateTime(n.createdAt)}</p>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </CardBody>
      </Card>
    </div>
  );
}
