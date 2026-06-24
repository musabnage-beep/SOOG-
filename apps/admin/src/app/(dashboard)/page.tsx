'use client';

import { DollarSign, ShoppingBag, Users, Package, TrendingUp, UserCog } from 'lucide-react';
import {
  useAdminDashboard,
  useDailySales,
  useTopProducts,
} from '@aldiafa/shared/client';
import {
  StatCard,
  Card,
  CardHeader,
  CardTitle,
  CardBody,
  Loading,
  ErrorState,
  EmptyState,
  SalesAreaChart,
  Badge,
  Table,
  THead,
  TBody,
  TR,
  TH,
  TD,
} from '@aldiafa/shared/ui';
import {
  money,
  num,
  ORDER_STATUS_LABEL_AR,
  ORDER_STATUS_TONE,
  type OrderStatus,
} from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

export default function DashboardPage() {
  const stats = useAdminDashboard();
  const sales = useDailySales(30);
  const top = useTopProducts(8);

  if (stats.isLoading) return <Loading label="جارٍ تحميل لوحة التحكم..." />;
  if (stats.isError || !stats.data)
    return <ErrorState onRetry={() => stats.refetch()} />;

  const d = stats.data;
  const chartData = (sales.data ?? [])
    .map((p) => ({
      label: new Date(p.day).toLocaleDateString('ar-SA', { day: 'numeric', month: 'short' }),
      revenue: p.revenue,
      orders: p.orders,
    }))
    .reverse();

  const statusEntries = Object.entries(d.ordersByStatus) as [OrderStatus, number][];

  return (
    <div>
      <PageHeader title="لوحة التحكم" subtitle="نظرة عامة على أداء المتجر" />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <StatCard
          label="إجمالي الإيرادات"
          value={money(d.totalRevenue)}
          icon={<DollarSign className="h-5 w-5" />}
          tone="bg-green-100 text-green-700"
        />
        <StatCard
          label="إيرادات الشهر"
          value={money(d.monthRevenue)}
          icon={<TrendingUp className="h-5 w-5" />}
          tone="bg-emerald-100 text-emerald-700"
        />
        <StatCard
          label="إجمالي الطلبات"
          value={num(d.orders)}
          icon={<ShoppingBag className="h-5 w-5" />}
          tone="bg-blue-100 text-blue-700"
        />
        <StatCard
          label="العملاء"
          value={num(d.customers)}
          icon={<Users className="h-5 w-5" />}
          tone="bg-violet-100 text-violet-700"
        />
        <StatCard
          label="الموظفون"
          value={num(d.employees)}
          icon={<UserCog className="h-5 w-5" />}
          tone="bg-amber-100 text-amber-700"
        />
        <StatCard
          label="المنتجات"
          value={num(d.products)}
          icon={<Package className="h-5 w-5" />}
          tone="bg-cyan-100 text-cyan-700"
        />
      </div>

      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>المبيعات آخر 30 يوماً</CardTitle>
          </CardHeader>
          <CardBody>
            {sales.isLoading ? (
              <Loading />
            ) : chartData.length === 0 ? (
              <EmptyState title="لا توجد بيانات مبيعات بعد" />
            ) : (
              <SalesAreaChart data={chartData} />
            )}
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>الطلبات حسب الحالة</CardTitle>
          </CardHeader>
          <CardBody>
            {statusEntries.length === 0 ? (
              <EmptyState title="لا توجد طلبات" />
            ) : (
              <div className="space-y-2">
                {statusEntries.map(([status, count]) => (
                  <div key={status} className="flex items-center justify-between">
                    <Badge tone={ORDER_STATUS_TONE[status]}>{ORDER_STATUS_LABEL_AR[status]}</Badge>
                    <span className="text-sm font-semibold text-gray-900">{num(count)}</span>
                  </div>
                ))}
              </div>
            )}
          </CardBody>
        </Card>
      </div>

      <Card className="mt-6">
        <CardHeader>
          <CardTitle>المنتجات الأكثر مبيعاً</CardTitle>
        </CardHeader>
        <CardBody className="p-0">
          {top.isLoading ? (
            <Loading />
          ) : !top.data || top.data.length === 0 ? (
            <EmptyState title="لا توجد مبيعات بعد" />
          ) : (
            <Table>
              <THead>
                <TR>
                  <TH>#</TH>
                  <TH>المنتج</TH>
                  <TH>الكمية المباعة</TH>
                  <TH>الإيراد</TH>
                </TR>
              </THead>
              <TBody>
                {top.data.map((p, i) => (
                  <TR key={p.productId}>
                    <TD className="text-gray-400">{i + 1}</TD>
                    <TD className="font-medium text-gray-900">{p.nameAr}</TD>
                    <TD>{num(p.unitsSold)}</TD>
                    <TD className="font-semibold text-brand">{money(p.revenue)}</TD>
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
