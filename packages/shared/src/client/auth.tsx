'use client';

import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import Cookies from 'js-cookie';
import { createApiClient, type AldiafaApi } from '../api';
import type { AuthUser, LoginInput, RoleName } from '../types';

interface AuthState {
  api: AldiafaApi;
  user: AuthUser | null;
  status: 'loading' | 'authenticated' | 'unauthenticated';
  login: (input: LoginInput) => Promise<AuthUser>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthState | null>(null);

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}

export function useApi(): AldiafaApi {
  return useAuth().api;
}

export interface AuthProviderProps {
  children: ReactNode;
  baseUrl: string;
  /** roles permitted to use this dashboard */
  allowedRoles: RoleName[];
  /** cookie namespace to keep admin/employee tokens separate */
  cookiePrefix: string;
}

export function AuthProvider({ children, baseUrl, allowedRoles, cookiePrefix }: AuthProviderProps) {
  const atKey = `${cookiePrefix}_at`;
  const rtKey = `${cookiePrefix}_rt`;

  const [user, setUser] = useState<AuthUser | null>(null);
  const [status, setStatus] = useState<AuthState['status']>('loading');

  // keep token accessors and handlers stable while reading the latest cookies
  const handlers = useRef({
    getToken: () => Cookies.get(atKey),
    getRefreshToken: () => Cookies.get(rtKey),
    setTokens: (accessToken: string, refreshToken: string) => {
      Cookies.set(atKey, accessToken, { sameSite: 'lax', expires: 1 });
      Cookies.set(rtKey, refreshToken, { sameSite: 'lax', expires: 30 });
    },
    clear: () => {
      Cookies.remove(atKey);
      Cookies.remove(rtKey);
    },
    onExpired: () => {},
  });

  const api = useMemo<AldiafaApi>(
    () =>
      createApiClient({
        baseUrl,
        getToken: () => handlers.current.getToken(),
        getRefreshToken: () => handlers.current.getRefreshToken(),
        onTokens: ({ accessToken, refreshToken }) =>
          handlers.current.setTokens(accessToken, refreshToken),
        onSessionExpired: () => handlers.current.onExpired(),
      }),
    [baseUrl],
  );

  // bind expiry handler to React state
  handlers.current.onExpired = () => {
    handlers.current.clear();
    setUser(null);
    setStatus('unauthenticated');
  };

  // bootstrap from existing cookie
  useEffect(() => {
    let active = true;
    (async () => {
      if (!handlers.current.getToken()) {
        setStatus('unauthenticated');
        return;
      }
      try {
        const me = await api.auth.me();
        if (!active) return;
        if (!allowedRoles.includes(me.role)) {
          handlers.current.clear();
          setUser(null);
          setStatus('unauthenticated');
          return;
        }
        setUser({
          id: me.id,
          fullName: me.fullName,
          email: me.email,
          phone: me.phone,
          role: me.role,
        });
        setStatus('authenticated');
      } catch {
        if (!active) return;
        handlers.current.clear();
        setUser(null);
        setStatus('unauthenticated');
      }
    })();
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [api]);

  const value: AuthState = {
    api,
    user,
    status,
    login: async (input) => {
      const result = await api.auth.login(input);
      if (!allowedRoles.includes(result.user.role)) {
        throw new Error('ليس لديك صلاحية الدخول إلى هذه اللوحة');
      }
      handlers.current.setTokens(result.accessToken, result.refreshToken);
      setUser(result.user);
      setStatus('authenticated');
      return result.user;
    },
    logout: async () => {
      const rt = handlers.current.getRefreshToken();
      if (rt) {
        try {
          await api.auth.logout(rt);
        } catch {
          /* ignore */
        }
      }
      handlers.current.clear();
      setUser(null);
      setStatus('unauthenticated');
    },
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
