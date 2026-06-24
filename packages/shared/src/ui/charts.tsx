'use client';

import {
  ResponsiveContainer,
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts';
import { BRAND } from '../constants';

export function SalesAreaChart({
  data,
}: {
  data: Array<{ label: string; revenue: number; orders: number }>;
}) {
  return (
    <ResponsiveContainer width="100%" height={280}>
      <AreaChart data={data} margin={{ top: 10, right: 12, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id="rev" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor={BRAND.secondary} stopOpacity={0.4} />
            <stop offset="95%" stopColor={BRAND.secondary} stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
        <XAxis dataKey="label" tick={{ fontSize: 11 }} reversed />
        <YAxis tick={{ fontSize: 11 }} orientation="right" width={56} />
        <Tooltip
          contentStyle={{ direction: 'rtl', borderRadius: 12, border: '1px solid #e5e7eb' }}
          formatter={(v: number) => [v, '']}
        />
        <Area
          type="monotone"
          dataKey="revenue"
          stroke={BRAND.primary}
          strokeWidth={2}
          fill="url(#rev)"
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}

export function OrdersBarChart({ data }: { data: Array<{ label: string; value: number }> }) {
  return (
    <ResponsiveContainer width="100%" height={280}>
      <BarChart data={data} margin={{ top: 10, right: 12, left: 0, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
        <XAxis dataKey="label" tick={{ fontSize: 11 }} reversed />
        <YAxis tick={{ fontSize: 11 }} orientation="right" width={40} allowDecimals={false} />
        <Tooltip contentStyle={{ direction: 'rtl', borderRadius: 12, border: '1px solid #e5e7eb' }} />
        <Bar dataKey="value" fill={BRAND.primary} radius={[6, 6, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}
