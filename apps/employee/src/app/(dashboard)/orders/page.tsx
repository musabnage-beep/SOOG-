'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Search, Eye } from 'lucide-react';
import { useOrders } from '@aldiafa/shared/client';
import {
  Card,
  CardBody,
  Input,
  Select,
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
  type OrderStatus,
} from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

const STATUSES: OrderStatus[] = [
  'SUBMITTED',
  'UNDER_REVIEW',
  'CONFIRMATION_REQUIRED',
  'APPROVED',
  'PREPARING',
  'READY',
  'OUT_FOR_DELIVERY',
  'DELIVERED',
  'PICKED_UP',
  'REJECTED',
  'CANCELLED',
];

export default function OrdersPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<OrderStatus | ''>('');

  const { data, isLoading, isError, refetch } = useOrders({
    page,
    limit: 20,
    search: search || undefined,
    status: status || undefined,
  });

  return (
    <div>
      <PageHeader title="الطلبات" subtitle="متابعة وتشغيل الطلبات" />

      <Card className="mb-4">
        <CardBody className="flex flex-wrap items-center gap-3">
          <div className="relative min-w-[220px] flex-1">
            <Search className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <Input
              className="pr-9"
              placeholder="بحث برقم الطلب أو اسم العميل..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
            />
          </div>
          <Select
            className="w-56"
            value={status}
            onChange={(e) => {
              setStatus(e.target.value as OrderStatus | '');
              setPage(1);
            }}
          >
            <option value="">كل الحالات</option>
            {STATUSES.map((s) => (
              <option key={s} value={s}>
                {ORDER_STATUS_LABEL_AR[s]}
              </option>
            ))}
          </Select>
        </CardBody>
      </Card>

      <Card>
        <CardBody className="p-0">
          {isLoading ? (
            <Loading />
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : !data || data.items.length === 0 ? (
            <EmptyState title="لا توجد طلبات" />
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
                          <Button variant="ghost" size="icon">
                            <Eye className="h-4 w-4" />
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
