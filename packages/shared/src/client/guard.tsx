'use client';

import { useEffect, type ReactNode } from 'react';
import { useAuth } from './auth';
import { Loading } from '../ui/state';

/**
 * Gate that renders children only for authenticated staff.
 * Redirects to `loginPath` (via injected `redirect`) otherwise.
 */
export function RequireAuth({
  children,
  loginPath,
  redirect,
}: {
  children: ReactNode;
  loginPath: string;
  redirect: (path: string) => void;
}) {
  const { status } = useAuth();

  useEffect(() => {
    if (status === 'unauthenticated') redirect(loginPath);
  }, [status, loginPath, redirect]);

  if (status !== 'authenticated') {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <Loading label="جارٍ التحقق من الجلسة..." />
      </div>
    );
  }
  return <>{children}</>;
}

/**
 * Inverse gate for the login page: redirect away if already authenticated.
 */
export function RedirectIfAuthed({
  children,
  homePath,
  redirect,
}: {
  children: ReactNode;
  homePath: string;
  redirect: (path: string) => void;
}) {
  const { status } = useAuth();

  useEffect(() => {
    if (status === 'authenticated') redirect(homePath);
  }, [status, homePath, redirect]);

  if (status === 'authenticated') {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <Loading />
      </div>
    );
  }
  return <>{children}</>;
}
