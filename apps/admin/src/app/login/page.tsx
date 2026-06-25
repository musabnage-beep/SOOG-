'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Mail, Phone, Lock } from 'lucide-react';
import { useAuth, RedirectIfAuthed } from '@aldiafa/shared/client';
import { Button, Input, Field, useToast, BrandLogo } from '@aldiafa/shared/ui';
import { ApiError } from '@aldiafa/shared';
import { HOME_PATH } from '@/lib/config';

function LoginForm() {
  const router = useRouter();
  const { login } = useAuth();
  const toast = useToast();
  const [mode, setMode] = useState<'email' | 'phone'>('email');
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await login({
        [mode]: identifier.trim(),
        password,
      });
      router.replace(HOME_PATH);
    } catch (err) {
      const message = err instanceof ApiError || err instanceof Error ? err.message : 'فشل تسجيل الدخول';
      toast.error(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-brand-dark p-4" dir="rtl">
      <div className="w-full max-w-md">
        <div className="mb-8 flex flex-col items-center text-center">
          <BrandLogo size={150} onDark />
          <p className="mt-3 text-sm text-white/60">لوحة تحكم الإدارة</p>
        </div>

        <div className="rounded-2xl bg-white p-6 shadow-xl">
          <div className="mb-5 flex rounded-lg bg-gray-100 p-1">
            <button
              type="button"
              onClick={() => setMode('email')}
              className={`flex flex-1 items-center justify-center gap-2 rounded-md py-2 text-sm font-medium transition-colors ${
                mode === 'email' ? 'bg-white text-brand shadow-sm' : 'text-gray-500'
              }`}
            >
              <Mail className="h-4 w-4" /> البريد
            </button>
            <button
              type="button"
              onClick={() => setMode('phone')}
              className={`flex flex-1 items-center justify-center gap-2 rounded-md py-2 text-sm font-medium transition-colors ${
                mode === 'phone' ? 'bg-white text-brand shadow-sm' : 'text-gray-500'
              }`}
            >
              <Phone className="h-4 w-4" /> الجوال
            </button>
          </div>

          <form onSubmit={submit} className="space-y-4">
            <Field label={mode === 'email' ? 'البريد الإلكتروني' : 'رقم الجوال'}>
              <Input
                type={mode === 'email' ? 'email' : 'tel'}
                dir="ltr"
                placeholder={mode === 'email' ? 'admin@aldiafa.sa' : '+9665XXXXXXXX'}
                value={identifier}
                onChange={(e) => setIdentifier(e.target.value)}
                required
              />
            </Field>
            <Field label="كلمة المرور">
              <div className="relative">
                <Lock className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <Input
                  type="password"
                  className="pr-9"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
              </div>
            </Field>
            <Button type="submit" size="lg" loading={loading} className="w-full">
              تسجيل الدخول
            </Button>
          </form>
        </div>
        <p className="mt-6 text-center text-xs text-white/40">
          © {new Date().getFullYear()} الضيافة — جميع الحقوق محفوظة
        </p>
      </div>
    </div>
  );
}

export default function LoginPage() {
  const router = useRouter();
  return (
    <RedirectIfAuthed homePath={HOME_PATH} redirect={(p) => router.replace(p)}>
      <LoginForm />
    </RedirectIfAuthed>
  );
}
