'use client';

import { DollarSign, ShoppingBag, Users, Package } from 'lucide-react';
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
  MonthlyBarChart,
} from '@aldiafa/shared/ui';
import {
  money,
  num,
} from '@aldiafa/shared';

export default function DashboardPage() {
  const stats = useAdminDashboard();
  const sales = useDailySales(180);
  const top = useTopProducts(8);

  if (stats.isLoading) return <Loading label="جارٍ تحميل لوحة التحكم..." />;
  if (stats.isError || !stats.data)
    return <ErrorState onRetry={() => stats.refetch()} />;

  const d = stats.data;

  // Aggregate daily sales into months
  const monthlyMap = new Map<string, { revenue: number; orders: number }>();
  for (const p of sales.data ?? []) {
    const date = new Date(p.day);
    const label = date.toLocaleDateString('ar-SA', { month: 'short', year: '2-digit' });
    const prev = monthlyMap.get(label) ?? { revenue: 0, orders: 0 };
    monthlyMap.set(label, { revenue: prev.revenue + p.revenue, orders: prev.orders + p.orders });
  }
  const chartData = Array.from(monthlyMap.entries())
    .slice(-6)
    .map(([label, v]) => ({ label, ...v }));

  return (
    <div>
      {/* 4 Stat cards */}
      <div className="grid grid-cols-2 gap-4 xl:grid-cols-4">
        <StatCard
          label="إجمالي الطلبات"
          value={num(d.orders)}
          icon={<ShoppingBag className="h-5 w-5" />}
          tone="bg-brand/10 text-brand"
        />
        <StatCard
          label="إجمالي المبيعات"
          value={money(d.totalRevenue)}
          icon={<DollarSign className="h-5 w-5" />}
          tone="bg-amber-100 text-amber-700"
        />
        <StatCard
          label="العملاء"
          value={num(d.customers)}
          icon={<Users className="h-5 w-5" />}
          tone="bg-blue-100 text-blue-700"
        />
        <StatCard
          label="المنتجات"
          value={num(d.products)}
          icon={<Package className="h-5 w-5" />}
          tone="bg-violet-100 text-violet-700"
        />
      </div>

      {/* Charts + top products */}
      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-5">
        {/* Monthly bar chart */}
        <Card className="lg:col-span-3">
          <CardHeader>
            <CardTitle>المبيعات</CardTitle>
          </CardHeader>
          <CardBody>
            {sales.isLoading ? (
              <Loading />
            ) : chartData.length === 0 ? (
              <EmptyState title="لا توجد بيانات مبيعات بعد" />
            ) : (
              <MonthlyBarChart data={chartData} />
            )}
          </CardBody>
        </Card>

        {/* Top products */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>أكثر المنتجات مبيعاً</CardTitle>
          </CardHeader>
          <CardBody className="divide-y divide-gray-100 p-0">
            {top.isLoading ? (
              <Loading />
            ) : !top.data || top.data.length === 0 ? (
              <EmptyState title="لا توجد مبيعات بعد" />
            ) : (
              top.data.map((p) => (
                <div key={p.productId} className="flex items-center gap-3 px-4 py-3">
                  {/* Product image */}
                  <div className="h-10 w-10 shrink-0 overflow-hidden rounded-lg bg-gray-100">
                    {p.imageUrl ? (
                      /* eslint-disable-next-line @next/next/no-img-element */
                      <img src={p.imageUrl} alt="" className="h-full w-full object-cover" />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center">
                        <Package className="h-5 w-5 text-gray-300" />
                      </div>
                    )}
                  </div>
                  {/* Name */}
                  <span className="min-w-0 flex-1 truncate text-sm font-medium text-gray-900">
                    {p.nameAr}
                  </span>
                  {/* Units sold */}
                  <span className="shrink-0 text-sm font-bold text-brand-gold">
                    {num(p.unitsSold)}
                  </span>
                </div>
              ))
            )}
          </CardBody>
        </Card>
      </div>
    </div>
  );
}
