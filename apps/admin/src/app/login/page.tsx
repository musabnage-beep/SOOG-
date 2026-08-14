'use client';

import { useRouter } from 'next/navigation';
import { LoginView } from '@aldiafa/shared/views';
import { HOME_PATH } from '@/lib/config';

export default function LoginPage() {
  const router = useRouter();
  return (
    <LoginView
      homePath={HOME_PATH}
      redirect={(p) => router.replace(p)}
      subtitle="لوحة تحكم الإدارة"
      emailPlaceholder="admin@aldiafa.sa"
      rightsNote="جميع الحقوق محفوظة"
    />
  );
}
