'use client';

import { use } from 'react';
import { useRouter } from 'next/navigation';
import { OrderDetailView } from '@aldiafa/shared/views';

export default function OrderDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  return <OrderDetailView orderId={id} onBack={() => router.push('/orders')} />;
}
