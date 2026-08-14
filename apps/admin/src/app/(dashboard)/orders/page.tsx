'use client';

import Link from 'next/link';
import { OrdersListView } from '@aldiafa/shared/views';

export default function OrdersPage() {
  return (
    <OrdersListView
      subtitle="إدارة ومتابعة جميع الطلبات"
      emptySubtitle="لم يتم العثور على طلبات مطابقة"
      Link={Link}
    />
  );
}
