'use client';

import Link from 'next/link';
import { Clock, ClipboardCheck, PackageX, ArrowLeft } from 'lucide-react';
import { useEmployeeDashboard } from '@aldiafa/shared/client';
import {
  StatCard,
  Card,
  CardHeader,
  CardTitle,
  CardBody,
  Badge,
  Button,
  Loading,
  ErrorState,
  EmptyState,
  Table,
  THead,
  TBody,
  TR,
  TH,
  TD,
} from '@aldiafa/shared/ui';
import {
  num,
  formatDateTime,
  ORDER_STATUS_LABEL_AR,
  ORDER_STATUS_TONE,
} from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

export default function EmployeeHomePage() {
  const { data, isLoading, isError, refetch } = useEmployeeDashboard();

  if (isLoading) return <Loading label="جارٍ التحميل..." />;
  if (isError || !data) return <ErrorState onRetry={() => refetch()} />;

  return (
    <div>
      <PageHeader title="الرئيسية" subtitle="نظرة سريعة على المهام" />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Link href="/review-queue">
          <StatCard
            label="بانتظار المراجعة"
            value={num(data.pending)}
            icon={<Clock className="h-5 w-5" />}
            tone="bg-amber-100 text-amber-700"
          />
        </Link>
        <Link href="/review-queue">
          <StatCard
            label="قيد المراجعة"
            value={num(data.underReview)}
            icon={<ClipboardCheck className="h-5 w-5" />}
            tone="bg-blue-100 text-blue-700"
          />
        </Link>
        <Link href="/inventory">
          <StatCard
            label="مخزون منخفض"
            value={num(data.lowStock)}
            icon={<PackageX className="h-5 w-5" />}
            tone="bg-red-100 text-red-700"
          />
        </Link>
      </div>

      <Card className="mt-6">
        <CardHeader className="flex items-center justify-between">
          <CardTitle>أحدث الطلبات</CardTitle>
          <Link href="/orders">
            <Button variant="ghost" size="sm">
              عرض الكل
              <ArrowLeft className="h-4 w-4" />
            </Button>
          </Link>
        </CardHeader>
        <CardBody className="p-0">
          {data.recent.length === 0 ? (
            <EmptyState title="لا توجد طلبات حديثة" />
          ) : (
            <Table>
              <THead>
                <TR>
                  <TH>رقم الطلب</TH>
                  <TH>العميل</TH>
                  <TH>العناصر</TH>
                  <TH>الحالة</TH>
                  <TH>التاريخ</TH>
                  <TH></TH>
                </TR>
              </THead>
              <TBody>
                {data.recent.map((o) => (
                  <TR key={o.id}>
                    <TD className="font-semibold text-gray-900">{o.orderNumber}</TD>
                    <TD>{o.user.fullName}</TD>
                    <TD>{o._count.items}</TD>
                    <TD>
                      <Badge tone={ORDER_STATUS_TONE[o.status]}>
                        {ORDER_STATUS_LABEL_AR[o.status]}
                      </Badge>
                    </TD>
                    <TD className="text-xs text-gray-500">{formatDateTime(o.submittedAt)}</TD>
                    <TD>
                      <Link href={`/orders/${o.id}`}>
                        <Button variant="ghost" size="sm">
                          فتح
                        </Button>
                      </Link>
                    </TD>
                  </TR>
                ))}
              </TBody>
            </Table>
          )}
        </CardBody>
      </Card>
    </div>
  );
}
