'use client';

import {
  useMutation,
  useQuery,
  useQueryClient,
  type UseQueryOptions,
} from '@tanstack/react-query';
import { useApi } from './auth';
import type {
  AdjustStockInput,
  CreateCategoryInput,
  CreateEmployeeInput,
  CreateProductInput,
  OrderQuery,
  OrderStatus,
  PageQuery,
  ProductQuery,
  UpdateCategoryInput,
  UpdateProductInput,
  UpdateSettingsInput,
  UpsertDeliveryZoneInput,
} from '../types';

export const qk = {
  dashboardEmployee: ['dashboard', 'employee'] as const,
  dashboardAdmin: ['dashboard', 'admin'] as const,
  dailySales: (days: number) => ['dashboard', 'daily-sales', days] as const,
  topProducts: (limit: number) => ['dashboard', 'top-products', limit] as const,
  orders: (q: OrderQuery) => ['orders', q] as const,
  reviewQueue: (q: OrderQuery) => ['orders', 'review-queue', q] as const,
  order: (id: string) => ['orders', id] as const,
  products: (q: ProductQuery) => ['products', q] as const,
  product: (id: string) => ['products', id] as const,
  categories: ['categories'] as const,
  lowStock: ['inventory', 'low-stock'] as const,
  invHistory: (id: string) => ['inventory', 'history', id] as const,
  customers: (q: PageQuery) => ['users', 'customers', q] as const,
  employees: (q: PageQuery) => ['users', 'employees', q] as const,
  zones: ['delivery', 'zones'] as const,
  settings: ['settings'] as const,
  audit: (q: PageQuery) => ['audit', q] as const,
  notifications: ['notifications'] as const,
  unreadCount: ['notifications', 'unread-count'] as const,
};

// ── dashboard ──────────────────────────────────────────────────────────────
export function useEmployeeDashboard() {
  const api = useApi();
  return useQuery({ queryKey: qk.dashboardEmployee, queryFn: () => api.dashboard.employee() });
}
export function useAdminDashboard() {
  const api = useApi();
  return useQuery({ queryKey: qk.dashboardAdmin, queryFn: () => api.dashboard.admin() });
}
export function useDailySales(days = 30) {
  const api = useApi();
  return useQuery({ queryKey: qk.dailySales(days), queryFn: () => api.dashboard.dailySales(days) });
}
export function useTopProducts(limit = 8) {
  const api = useApi();
  return useQuery({
    queryKey: qk.topProducts(limit),
    queryFn: () => api.dashboard.topProducts(limit),
  });
}

// ── orders ─────────────────────────────────────────────────────────────────
export function useOrders(q: OrderQuery) {
  const api = useApi();
  return useQuery({ queryKey: qk.orders(q), queryFn: () => api.orders.list(q) });
}
export function useReviewQueue(q: OrderQuery) {
  const api = useApi();
  return useQuery({
    queryKey: qk.reviewQueue(q),
    queryFn: () => api.orders.reviewQueue(q),
    refetchInterval: 20_000,
    refetchOnWindowFocus: true,
  });
}
export function useOrder(id: string, options?: Partial<UseQueryOptions>) {
  const api = useApi();
  return useQuery({
    queryKey: qk.order(id),
    queryFn: () => api.orders.detail(id),
    enabled: !!id,
    ...(options as object),
  });
}

export function useOrderActions(id: string) {
  const api = useApi();
  const qc = useQueryClient();
  const invalidate = () => {
    qc.invalidateQueries({ queryKey: qk.order(id) });
    qc.invalidateQueries({ queryKey: ['orders'] });
    qc.invalidateQueries({ queryKey: ['dashboard'] });
  };
  return {
    review: useMutation({ mutationFn: () => api.orders.review(id), onSuccess: invalidate }),
    approve: useMutation({ mutationFn: () => api.orders.approve(id), onSuccess: invalidate }),
    reject: useMutation({
      mutationFn: (reason: string) => api.orders.reject(id, reason),
      onSuccess: invalidate,
    }),
    requestConfirmation: useMutation({
      mutationFn: (vars: { unavailableItems: { orderItemId: string }[]; note?: string }) =>
        api.orders.requestConfirmation(id, vars.unavailableItems, vars.note),
      onSuccess: invalidate,
    }),
    advance: useMutation({
      mutationFn: (vars: { status: OrderStatus; note?: string }) =>
        api.orders.advance(id, vars.status, vars.note),
      onSuccess: invalidate,
    }),
  };
}

// ── products ───────────────────────────────────────────────────────────────
export function useProducts(q: ProductQuery) {
  const api = useApi();
  return useQuery({ queryKey: qk.products(q), queryFn: () => api.products.list(q) });
}
export function useProduct(id: string) {
  const api = useApi();
  return useQuery({ queryKey: qk.product(id), queryFn: () => api.products.detail(id), enabled: !!id });
}
export function useProductMutations() {
  const api = useApi();
  const qc = useQueryClient();
  const invalidate = () => qc.invalidateQueries({ queryKey: ['products'] });
  return {
    create: useMutation({
      mutationFn: (input: CreateProductInput) => api.products.create(input),
      onSuccess: invalidate,
    }),
    update: useMutation({
      mutationFn: (vars: { id: string; input: UpdateProductInput }) =>
        api.products.update(vars.id, vars.input),
      onSuccess: invalidate,
    }),
    remove: useMutation({
      mutationFn: (id: string) => api.products.remove(id),
      onSuccess: invalidate,
    }),
    uploadImages: useMutation({
      mutationFn: (vars: { productId: string; files: File[] }) =>
        api.products.uploadImages(vars.productId, vars.files),
      onSuccess: invalidate,
    }),
    setMainImage: useMutation({
      mutationFn: (vars: { productId: string; imageId: string }) =>
        api.products.setMainImage(vars.productId, vars.imageId),
      onSuccess: invalidate,
    }),
    deleteImage: useMutation({
      mutationFn: (vars: { productId: string; imageId: string }) =>
        api.products.deleteImage(vars.productId, vars.imageId),
      onSuccess: invalidate,
    }),
  };
}

// ── categories ─────────────────────────────────────────────────────────────
export function useCategories() {
  const api = useApi();
  return useQuery({ queryKey: qk.categories, queryFn: () => api.categories.list(true) });
}
export function useCategoryMutations() {
  const api = useApi();
  const qc = useQueryClient();
  const invalidate = () => qc.invalidateQueries({ queryKey: qk.categories });
  return {
    create: useMutation({
      mutationFn: (input: CreateCategoryInput) => api.categories.create(input),
      onSuccess: invalidate,
    }),
    update: useMutation({
      mutationFn: (vars: { id: string; input: UpdateCategoryInput }) =>
        api.categories.update(vars.id, vars.input),
      onSuccess: invalidate,
    }),
    remove: useMutation({
      mutationFn: (id: string) => api.categories.remove(id),
      onSuccess: invalidate,
    }),
  };
}

// ── inventory ──────────────────────────────────────────────────────────────
export function useLowStock() {
  const api = useApi();
  return useQuery({ queryKey: qk.lowStock, queryFn: () => api.inventory.lowStock() });
}
export function useInventoryHistory(productId: string) {
  const api = useApi();
  return useQuery({
    queryKey: qk.invHistory(productId),
    queryFn: () => api.inventory.history(productId),
    enabled: !!productId,
  });
}
export function useAdjustStock() {
  const api = useApi();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (vars: { productId: string; input: AdjustStockInput }) =>
      api.inventory.adjust(vars.productId, vars.input),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['inventory'] });
      qc.invalidateQueries({ queryKey: ['products'] });
    },
  });
}

// ── users ──────────────────────────────────────────────────────────────────
export function useCustomers(q: PageQuery) {
  const api = useApi();
  return useQuery({ queryKey: qk.customers(q), queryFn: () => api.users.customers(q) });
}
export function useEmployees(q: PageQuery) {
  const api = useApi();
  return useQuery({ queryKey: qk.employees(q), queryFn: () => api.users.employees(q) });
}
export function useUserMutations() {
  const api = useApi();
  const qc = useQueryClient();
  const invalidate = () => qc.invalidateQueries({ queryKey: ['users'] });
  return {
    createEmployee: useMutation({
      mutationFn: (input: CreateEmployeeInput) => api.users.createEmployee(input),
      onSuccess: invalidate,
    }),
    setStatus: useMutation({
      mutationFn: (vars: { id: string; isActive: boolean }) =>
        api.users.setStatus(vars.id, vars.isActive),
      onSuccess: invalidate,
    }),
  };
}

// ── delivery ───────────────────────────────────────────────────────────────
export function useZones() {
  const api = useApi();
  return useQuery({ queryKey: qk.zones, queryFn: () => api.delivery.zones() });
}
export function useZoneMutations() {
  const api = useApi();
  const qc = useQueryClient();
  const invalidate = () => qc.invalidateQueries({ queryKey: qk.zones });
  return {
    create: useMutation({
      mutationFn: (input: UpsertDeliveryZoneInput) => api.delivery.createZone(input),
      onSuccess: invalidate,
    }),
    update: useMutation({
      mutationFn: (vars: { id: string; input: UpsertDeliveryZoneInput }) =>
        api.delivery.updateZone(vars.id, vars.input),
      onSuccess: invalidate,
    }),
    remove: useMutation({
      mutationFn: (id: string) => api.delivery.deleteZone(id),
      onSuccess: invalidate,
    }),
  };
}

// ── settings ───────────────────────────────────────────────────────────────
export function useSettings() {
  const api = useApi();
  return useQuery({ queryKey: qk.settings, queryFn: () => api.settings.get() });
}
export function useUpdateSettings() {
  const api = useApi();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: UpdateSettingsInput) => api.settings.update(input),
    onSuccess: () => qc.invalidateQueries({ queryKey: qk.settings }),
  });
}

// ── audit ──────────────────────────────────────────────────────────────────
export function useAudit(q: PageQuery) {
  const api = useApi();
  return useQuery({ queryKey: qk.audit(q), queryFn: () => api.audit.list(q) });
}

// ── notifications ──────────────────────────────────────────────────────────
export function useNotifications(unreadOnly = false) {
  const api = useApi();
  return useQuery({
    queryKey: qk.notifications,
    queryFn: () => api.notifications.list(unreadOnly),
  });
}
export function useUnreadCount() {
  const api = useApi();
  return useQuery({
    queryKey: qk.unreadCount,
    queryFn: () => api.notifications.unreadCount(),
    refetchInterval: 60_000,
  });
}
export function useNotificationActions() {
  const api = useApi();
  const qc = useQueryClient();
  const invalidate = () => qc.invalidateQueries({ queryKey: ['notifications'] });
  return {
    markRead: useMutation({ mutationFn: (id: string) => api.notifications.markRead(id), onSuccess: invalidate }),
    markAllRead: useMutation({ mutationFn: () => api.notifications.markAllRead(), onSuccess: invalidate }),
  };
}
