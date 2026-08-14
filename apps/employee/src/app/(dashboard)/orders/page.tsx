'use client';

import Link from 'next/link';
import { OrdersListView } from '@aldiafa/shared/views';

export default function OrdersPage() {
  return <OrdersListView subtitle="متابعة وتشغيل الطلبات" Link={Link} />;
}
