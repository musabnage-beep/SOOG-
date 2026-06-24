'use client';

import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { useReviewQueue } from '@aldiafa/shared/client';
import {
  Card,
  CardBody,
  Badge,
  Button,
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
import {
  money,
  formatDateTime,
  ORDER_STATUS_LABEL_AR,
  ORDER_STATUS_TONE,
  FULFILLMENT_LABEL_AR,
} from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

export default function ReviewQueuePage() {
  const [page, setPage] = useState(1);
  const { data, isLoading, isError, refetch } = useReviewQueue({ page, limit: 20 });

  return (
    <div>
      <PageHeader title="قائمة المراجعة" subtitle="الطلبات التي تحتاج إلى إجراء" />

      <Card>
        <CardBody className="p-0">
          {isLoading ? (
            <Loading />
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : !data || data.items.length === 0 ? (
            <EmptyState title="لا توجد طلبات للمراجعة" subtitle="تم إنجاز كل المهام 🎉" />
          ) : (
            <>
              <Table>
                <THead>
                  <TR>
                    <TH>رقم الطلب</TH>
                    <TH>العميل</TH>
                    <TH>النوع</TH>
                    <TH>الحالة</TH>
                    <TH>الإجمالي</TH>
                    <TH>التاريخ</TH>
                    <TH></TH>
                  </TR>
                </THead>
                <TBody>
                  {data.items.map((o) => (
                    <TR key={o.id}>
                      <TD className="font-semibold text-gray-900">{o.orderNumber}</TD>
                      <TD>{o.user?.fullName ?? '—'}</TD>
                      <TD>{FULFILLMENT_LABEL_AR[o.fulfillmentType]}</TD>
                      <TD>
                        <Badge tone={ORDER_STATUS_TONE[o.status]}>
                          {ORDER_STATUS_LABEL_AR[o.status]}
                        </Badge>
                      </TD>
                      <TD className="font-semibold text-brand">{money(o.total)}</TD>
                      <TD className="text-xs text-gray-500">{formatDateTime(o.submittedAt)}</TD>
                      <TD>
                        <Link href={`/orders/${o.id}`}>
                          <Button size="sm">
                            مراجعة
                            <ArrowLeft className="h-4 w-4" />
                          </Button>
                        </Link>
                      </TD>
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
