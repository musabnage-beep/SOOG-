import {
  LayoutDashboard,
  ClipboardList,
  ShoppingBag,
  Boxes,
} from 'lucide-react';
import type { NavItem } from '@aldiafa/shared/client';

export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000/api';
export const COOKIE_PREFIX = 'aldiafa_emp';
export const LOGIN_PATH = '/login';
export const HOME_PATH = '/';

export const NAV: NavItem[] = [
  { href: '/', label: 'الرئيسية', icon: LayoutDashboard },
  { href: '/review-queue', label: 'قائمة المراجعة', icon: ClipboardList },
  { href: '/orders', label: 'الطلبات', icon: ShoppingBag },
  { href: '/inventory', label: 'المخزون', icon: Boxes },
];
