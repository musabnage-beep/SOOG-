'use client';

import Link from 'next/link';
import { ShoppingBag, PackageCheck, CheckCircle, DollarSign } from 'lucide-react';
import { useEmployeeDashboard } from '@aldiafa/shared/client';
import {
  Card,
  CardHeader,
  CardTitle,
  CardBody,
  StatCard,
  Loading,
  ErrorState,
  OrdersLineChart,
  DonutChart,
} from '@aldiafa/shared/ui';
import {
  num,
  money,
  ORDER_STATUS_LABEL_AR,
} from '@aldiafa/shared';

export default function EmployeeHomePage() {
  const { data, isLoading, isError, refetch } = useEmployeeDashboard();

  if (isLoading) return <Loading label="جارٍ التحميل..." />;
  if (isError || !data) return <ErrorState onRetry={() => refetch()} />;

  const lineData = (data.dailyOrders ?? []).map((d) => ({
    label: new Date(d.day).toLocaleDateString('ar-SA', { day: 'numeric', month: 'short' }),
    orders: d.orders,
  }));

  const donutData = Object.entries(data.ordersByStatus ?? {})
    .filter(([, v]) => (v ?? 0) > 0)
    .map(([status, value]) => ({
      name: ORDER_STATUS_LABEL_AR[status as keyof typeof ORDER_STATUS_LABEL_AR] ?? status,
      value: value ?? 0,
    }));

  return (
    <div>
      {/* 4 Stat cards */}
      <div className="grid grid-cols-2 gap-4 xl:grid-cols-4">
        <Link href="/orders">
          <StatCard
            label="إجمالي الطلبات"
            value={num(data.totalOrders ?? 0)}
            icon={<ShoppingBag className="h-5 w-5" />}
            tone="bg-brand/10 text-brand"
          />
        </Link>
        <Link href="/orders">
          <StatCard
            label="قيد التجهيز"
            value={num(data.preparing ?? 0)}
            icon={<PackageCheck className="h-5 w-5" />}
            tone="bg-blue-100 text-blue-700"
          />
        </Link>
        <Link href="/orders">
          <StatCard
            label="تم التوصيل"
            value={num(data.delivered ?? 0)}
            icon={<CheckCircle className="h-5 w-5" />}
            tone="bg-emerald-100 text-emerald-700"
          />
        </Link>
        <StatCard
          label="إجمالي المبيعات"
          value={money(data.totalRevenue ?? 0)}
          icon={<DollarSign className="h-5 w-5" />}
          tone="bg-amber-100 text-amber-700"
        />
      </div>

      {/* Charts row */}
      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>الطلبات خلال آخر 7 أيام</CardTitle>
          </CardHeader>
          <CardBody>
            {lineData.length === 0 ? (
              <p className="py-12 text-center text-sm text-gray-400">لا توجد بيانات بعد</p>
            ) : (
              <OrdersLineChart data={lineData} />
            )}
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>حالة الطلبات</CardTitle>
          </CardHeader>
          <CardBody>
            {donutData.length === 0 ? (
              <p className="py-12 text-center text-sm text-gray-400">لا توجد طلبات</p>
            ) : (
              <DonutChart data={donutData} />
            )}
          </CardBody>
        </Card>
      </div>
    </div>
  );
}
