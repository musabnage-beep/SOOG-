'use client';

import { useState } from 'react';
import { Search } from 'lucide-react';
import { useAudit } from '@aldiafa/shared/client';
import {
  Card,
  CardBody,
  Input,
  Badge,
  Table,
  THead,
  TBody,
  TR,
  TH,
  TD,
  Loading,
  ErrorState,
  EmptyState,
  Pagination,
} from '@aldiafa/shared/ui';
import { formatDateTime } from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

export default function ActivityLogsPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const { data, isLoading, isError, refetch } = useAudit({
    page,
    limit: 30,
    search: search || undefined,
  });

  return (
    <div>
      <PageHeader title="سجل النشاط" subtitle="تتبّع العمليات على النظام" />

      <Card className="mb-4">
        <CardBody>
          <div className="relative max-w-md">
            <Search className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <Input
              className="pr-9"
              placeholder="بحث بالإجراء أو الكيان..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
            />
          </div>
        </CardBody>
      </Card>

      <Card>
        <CardBody className="p-0">
          {isLoading ? (
            <Loading />
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : !data || data.items.length === 0 ? (
            <EmptyState title="لا يوجد نشاط" />
          ) : (
            <>
              <Table>
                <THead>
                  <TR>
                    <TH>المستخدم</TH>
                    <TH>الإجراء</TH>
                    <TH>الكيان</TH>
                    <TH>IP</TH>
                    <TH>التاريخ</TH>
                  </TR>
                </THead>
                <TBody>
                  {data.items.map((log) => (
                    <TR key={log.id}>
                      <TD className="font-medium text-gray-900">{log.user?.fullName ?? 'النظام'}</TD>
                      <TD>
                        <Badge tone="bg-blue-100 text-blue-800">{log.action}</Badge>
                      </TD>
                      <TD className="text-xs text-gray-500" dir="ltr">
                        {log.entity}
                        {log.entityId ? `#${log.entityId.slice(0, 8)}` : ''}
                      </TD>
                      <TD className="text-xs text-gray-400" dir="ltr">{log.ip ?? '—'}</TD>
                      <TD className="text-xs text-gray-500">{formatDateTime(log.createdAt)}</TD>
                    </TR>
                  ))}
                </TBody>
              </Table>
              <Pagination page={page} totalPages={data.meta.totalPages} onChange={setPage} />
            </>
          )}
        </CardBody>
      </Card>
    </div>
  );
}
