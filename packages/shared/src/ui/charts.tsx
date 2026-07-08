'use client';

import {
  ResponsiveContainer,
  AreaChart,
  Area,
  BarChart,
  Bar,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  Legend,
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

export function MonthlyBarChart({
  data,
}: {
  data: Array<{ label: string; revenue: number; orders: number }>;
}) {
  return (
    <ResponsiveContainer width="100%" height={280}>
      <BarChart data={data} margin={{ top: 10, right: 12, left: 0, bottom: 0 }} barGap={2}>
        <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
        <XAxis dataKey="label" tick={{ fontSize: 11 }} reversed />
        <YAxis tick={{ fontSize: 11 }} orientation="right" width={56} />
        <Tooltip
          contentStyle={{ direction: 'rtl', borderRadius: 12, border: '1px solid #e5e7eb' }}
        />
        <Bar dataKey="revenue" name="الإيراد" fill={BRAND.primary} radius={[4, 4, 0, 0]} />
        <Bar dataKey="orders" name="الطلبات" fill={BRAND.gold} radius={[4, 4, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}

export function OrdersLineChart({
  data,
}: {
  data: Array<{ label: string; orders: number }>;
}) {
  return (
    <ResponsiveContainer width="100%" height={240}>
      <LineChart data={data} margin={{ top: 10, right: 12, left: 0, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#1f2d1f" />
        <XAxis dataKey="label" tick={{ fontSize: 11, fill: '#a3c9a3' }} reversed />
        <YAxis
          tick={{ fontSize: 11, fill: '#a3c9a3' }}
          orientation="right"
          width={36}
          allowDecimals={false}
        />
        <Tooltip
          contentStyle={{
            direction: 'rtl',
            borderRadius: 12,
            border: '1px solid #2d4d2d',
            background: '#0d1f0d',
            color: '#fff',
          }}
        />
        <Line
          type="monotone"
          dataKey="orders"
          name="الطلبات"
          stroke={BRAND.secondary}
          strokeWidth={2.5}
          dot={{ fill: BRAND.secondary, r: 4 }}
          activeDot={{ r: 6 }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}

const DONUT_COLORS = ['#D4AF37', '#3B82F6', '#EF4444', '#22C55E', '#8B5CF6', '#F97316', '#6B7280'];

export function DonutChart({
  data,
}: {
  data: Array<{ name: string; value: number }>;
}) {
  return (
    <ResponsiveContainer width="100%" height={220}>
      <PieChart>
        <Pie
          data={data}
          cx="50%"
          cy="50%"
          innerRadius={55}
          outerRadius={85}
          paddingAngle={3}
          dataKey="value"
        >
          {data.map((_, i) => (
            <Cell key={i} fill={DONUT_COLORS[i % DONUT_COLORS.length]} />
          ))}
        </Pie>
        <Tooltip
          contentStyle={{ direction: 'rtl', borderRadius: 12, border: '1px solid #2d4d2d', background: '#0d1f0d', color: '#fff' }}
        />
        <Legend
          iconType="circle"
          iconSize={8}
          formatter={(value) => <span style={{ color: '#ccc', fontSize: 11 }}>{value}</span>}
        />
      </PieChart>
    </ResponsiveContainer>
  );
}
