import {
  LayoutDashboard,
  ShoppingBag,
  Package,
  Tags,
  Boxes,
  Users,
  UserCog,
  Truck,
  FileBarChart,
  Settings,
  ScrollText,
} from 'lucide-react';
import type { NavItem } from '@aldiafa/shared/client';

export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000/api';
export const COOKIE_PREFIX = 'aldiafa_admin';
export const LOGIN_PATH = '/login';
export const HOME_PATH = '/';

export const NAV: NavItem[] = [
  { href: '/', label: 'لوحة التحكم', icon: LayoutDashboard },
  { href: '/orders', label: 'الطلبات', icon: ShoppingBag },
  { href: '/products', label: 'المنتجات', icon: Package },
  { href: '/categories', label: 'التصنيفات', icon: Tags },
  { href: '/inventory', label: 'المخزون', icon: Boxes },
  { href: '/customers', label: 'العملاء', icon: Users },
  { href: '/employees', label: 'الموظفون', icon: UserCog },
  { href: '/delivery', label: 'مناطق التوصيل', icon: Truck },
  { href: '/reports', label: 'التقارير', icon: FileBarChart },
  { href: '/activity-logs', label: 'سجل النشاط', icon: ScrollText },
  { href: '/settings', label: 'الإعدادات', icon: Settings },
];
