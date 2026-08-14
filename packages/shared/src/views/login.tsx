'use client';

import { useState, type FormEvent, type ReactNode } from 'react';
import { Mail, Phone, Lock } from 'lucide-react';
import { useAuth } from '../client/auth';
import { RedirectIfAuthed } from '../client/guard';
import { Button, Input, Field, useToast, BrandLogo } from '../ui';
import { ApiError } from '../api';

interface LoginViewProps {
  /** Path to land on once the session is valid. */
  homePath: string;
  redirect: (path: string) => void;
  /** Caption under the logo, e.g. "لوحة تحكم الإدارة". */
  subtitle: string;
  emailPlaceholder: string;
  /** Optional suffix appended to the copyright line. */
  rightsNote?: string;
}

export function LoginView(props: LoginViewProps) {
  return (
    <RedirectIfAuthed homePath={props.homePath} redirect={props.redirect}>
      <LoginForm {...props} />
    </RedirectIfAuthed>
  );
}

function LoginForm({ homePath, redirect, subtitle, emailPlaceholder, rightsNote }: LoginViewProps) {
  const { login } = useAuth();
  const toast = useToast();
  const [mode, setMode] = useState<'email' | 'phone'>('email');
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await login({ [mode]: identifier.trim(), password });
      redirect(homePath);
    } catch (err) {
      const message =
        err instanceof ApiError || err instanceof Error ? err.message : 'فشل تسجيل الدخول';
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
          <p className="mt-3 text-sm text-white/60">{subtitle}</p>
        </div>

        <div className="rounded-2xl bg-white p-6 shadow-xl">
          <div className="mb-5 flex rounded-lg bg-gray-100 p-1">
            <ModeTab active={mode === 'email'} onClick={() => setMode('email')}>
              <Mail className="h-4 w-4" /> البريد
            </ModeTab>
            <ModeTab active={mode === 'phone'} onClick={() => setMode('phone')}>
              <Phone className="h-4 w-4" /> الجوال
            </ModeTab>
          </div>

          <form onSubmit={submit} className="space-y-4">
            <Field label={mode === 'email' ? 'البريد الإلكتروني' : 'رقم الجوال'}>
              <Input
                type={mode === 'email' ? 'email' : 'tel'}
                dir="ltr"
                placeholder={mode === 'email' ? emailPlaceholder : '+9665XXXXXXXX'}
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
          © {new Date().getFullYear()} الضيافة{rightsNote ? ` — ${rightsNote}` : ''}
        </p>
      </div>
    </div>
  );
}

function ModeTab({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex flex-1 items-center justify-center gap-2 rounded-md py-2 text-sm font-medium transition-colors ${
        active ? 'bg-white text-brand shadow-sm' : 'text-gray-500'
      }`}
    >
      {children}
    </button>
  );
}
