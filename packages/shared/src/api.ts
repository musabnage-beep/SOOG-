import axios, {
  type AxiosInstance,
  type AxiosError,
  type AxiosRequestConfig,
} from 'axios';
import type {
  ActivityLog,
  AdjustStockInput,
  AdminDashboard,
  AppNotification,
  AuthResult,
  Category,
  CreateCategoryInput,
  CreateEmployeeInput,
  CreateProductInput,
  DailySalesPoint,
  DeliveryZone,
  EmployeeDashboard,
  InventoryLog,
  LoginInput,
  Order,
  OrderQuery,
  OrderStatus,
  PageQuery,
  Paginated,
  Product,
  ProductImage,
  ProductQuery,
  ReportData,
  ReportFormat,
  ReportType,
  StoreSettings,
  TopProduct,
  UpdateCategoryInput,
  UpdateProductInput,
  UpdateSettingsInput,
  UpsertDeliveryZoneInput,
  UserAccount,
} from './types';

export class ApiError extends Error {
  status: number;
  raw: unknown;
  constructor(message: string, status: number, raw?: unknown) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.raw = raw;
  }
}

export interface ApiClientOptions {
  baseUrl: string;
  getToken: () => string | undefined;
  getRefreshToken: () => string | undefined;
  /** persist a freshly rotated token pair */
  onTokens: (tokens: { accessToken: string; refreshToken: string }) => void;
  /** called when refresh fails / session is unrecoverable */
  onSessionExpired: () => void;
}

function unwrap<T>(data: unknown): T {
  if (data && typeof data === 'object' && 'success' in data && 'data' in data) {
    return (data as { data: T }).data;
  }
  return data as T;
}

function toApiError(err: AxiosError): ApiError {
  const status = err.response?.status ?? 0;
  const body = err.response?.data as { message?: string | string[]; error?: string } | undefined;
  let message = 'حدث خطأ غير متوقع';
  if (body?.message) {
    message = Array.isArray(body.message) ? body.message.join('، ') : body.message;
  } else if (status === 0) {
    message = 'تعذّر الاتصال بالخادم';
  } else if (err.message) {
    message = err.message;
  }
  return new ApiError(message, status, body);
}

export function createApiClient(opts: ApiClientOptions) {
  const http: AxiosInstance = axios.create({
    baseURL: opts.baseUrl.replace(/\/$/, ''),
    timeout: 30000,
  });
  // bare instance for token refresh to avoid interceptor recursion
  const refreshHttp: AxiosInstance = axios.create({
    baseURL: opts.baseUrl.replace(/\/$/, ''),
    timeout: 30000,
  });

  http.interceptors.request.use((config) => {
    const token = opts.getToken();
    if (token) {
      config.headers = config.headers ?? {};
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  });

  let refreshing: Promise<string | null> | null = null;

  async function doRefresh(): Promise<string | null> {
    const refreshToken = opts.getRefreshToken();
    if (!refreshToken) return null;
    try {
      const res = await refreshHttp.post('/auth/refresh', { refreshToken });
      const tokens = unwrap<AuthResult>(res.data);
      opts.onTokens({ accessToken: tokens.accessToken, refreshToken: tokens.refreshToken });
      return tokens.accessToken;
    } catch {
      return null;
    }
  }

  http.interceptors.response.use(
    (res) => res,
    async (error: AxiosError) => {
      const original = error.config as (AxiosRequestConfig & { _retried?: boolean }) | undefined;
      if (error.response?.status === 401 && original && !original._retried && opts.getRefreshToken()) {
        original._retried = true;
        refreshing = refreshing ?? doRefresh();
        const newToken = await refreshing;
        refreshing = null;
        if (newToken) {
          original.headers = original.headers ?? {};
          (original.headers as Record<string, string>).Authorization = `Bearer ${newToken}`;
          return http.request(original);
        }
        opts.onSessionExpired();
      }
      return Promise.reject(toApiError(error));
    },
  );

  async function get<T>(url: string, params?: Record<string, unknown>): Promise<T> {
    const res = await http.get(url, { params });
    return unwrap<T>(res.data);
  }
  async function post<T>(url: string, body?: unknown): Promise<T> {
    const res = await http.post(url, body);
    return unwrap<T>(res.data);
  }
  async function patch<T>(url: string, body?: unknown): Promise<T> {
    const res = await http.patch(url, body);
    return unwrap<T>(res.data);
  }
  async function put<T>(url: string, body?: unknown): Promise<T> {
    const res = await http.put(url, body);
    return unwrap<T>(res.data);
  }
  async function del<T>(url: string): Promise<T> {
    const res = await http.delete(url);
    return unwrap<T>(res.data);
  }

  return {
    http,
    // ── auth ──────────────────────────────────────────────────────────────
    auth: {
      login: (input: LoginInput) => post<AuthResult>('/auth/login', input),
      logout: (refreshToken: string) => post<{ ok: boolean }>('/auth/logout', { refreshToken }),
      me: () => get<UserAccount>('/users/me'),
    },
    // ── dashboard ─────────────────────────────────────────────────────────
    dashboard: {
      employee: () => get<EmployeeDashboard>('/dashboard/employee'),
      admin: () => get<AdminDashboard>('/dashboard/admin'),
      dailySales: (days = 30) =>
        get<DailySalesPoint[]>('/dashboard/admin/daily-sales', { days }),
      topProducts: (limit = 10) => get<TopProduct[]>('/dashboard/admin/top-products', { limit }),
    },
    // ── orders ────────────────────────────────────────────────────────────
    orders: {
      list: (q: OrderQuery = {}) => get<Paginated<Order>>('/orders', q as Record<string, unknown>),
      reviewQueue: (q: OrderQuery = {}) =>
        get<Paginated<Order>>('/orders/review-queue', q as Record<string, unknown>),
      detail: (id: string) => get<Order>(`/orders/${id}`),
      review: (id: string) => patch<Order>(`/orders/${id}/review`),
      approve: (id: string) => patch<Order>(`/orders/${id}/approve`),
      reject: (id: string, reason: string) => patch<Order>(`/orders/${id}/reject`, { reason }),
      requestConfirmation: (id: string, unavailableItems: { orderItemId: string }[], note?: string) =>
        patch<Order>(`/orders/${id}/request-confirmation`, { unavailableItems, note }),
      advance: (id: string, status: OrderStatus, note?: string) =>
        patch<Order>(`/orders/${id}/status`, { status, note }),
    },
    // ── products ──────────────────────────────────────────────────────────
    products: {
      list: (q: ProductQuery = {}) =>
        get<Paginated<Product>>('/products', q as Record<string, unknown>),
      detail: (id: string) => get<Product>(`/products/${id}`),
      create: (input: CreateProductInput) => post<Product>('/products', input),
      update: (id: string, input: UpdateProductInput) => patch<Product>(`/products/${id}`, input),
      remove: (id: string) => del<{ ok: boolean }>(`/products/${id}`),
      uploadImages: async (productId: string, files: File[]) => {
        const form = new FormData();
        files.forEach((f) => form.append('files', f));
        const res = await http.post(`/products/${productId}/images`, form, {
          headers: { 'Content-Type': 'multipart/form-data' },
        });
        return unwrap<ProductImage[]>(res.data);
      },
      setMainImage: (productId: string, imageId: string) =>
        patch<{ ok: boolean }>(`/products/${productId}/images/${imageId}/main`),
      reorderImages: (productId: string, orderedIds: string[]) =>
        patch<{ ok: boolean }>(`/products/${productId}/images/reorder`, { orderedIds }),
      deleteImage: (productId: string, imageId: string) =>
        del<{ ok: boolean }>(`/products/${productId}/images/${imageId}`),
    },
    // ── categories ────────────────────────────────────────────────────────
    categories: {
      list: (includeInactive = true) =>
        get<Category[]>('/categories', includeInactive ? { includeInactive: 'true' } : undefined),
      create: (input: CreateCategoryInput) => post<Category>('/categories', input),
      update: (id: string, input: UpdateCategoryInput) =>
        patch<Category>(`/categories/${id}`, input),
      remove: (id: string) => del<{ ok: boolean }>(`/categories/${id}`),
    },
    // ── inventory ─────────────────────────────────────────────────────────
    inventory: {
      lowStock: () => get<Product[]>('/inventory/low-stock'),
      history: (productId: string) => get<InventoryLog[]>(`/inventory/${productId}/history`),
      adjust: (productId: string, input: AdjustStockInput) =>
        post<{ ok: boolean }>(`/inventory/${productId}/adjust`, input),
    },
    // ── users ─────────────────────────────────────────────────────────────
    users: {
      customers: (q: PageQuery = {}) =>
        get<Paginated<UserAccount>>('/users/customers', q as Record<string, unknown>),
      employees: (q: PageQuery = {}) =>
        get<Paginated<UserAccount>>('/users/employees', q as Record<string, unknown>),
      createEmployee: (input: CreateEmployeeInput) =>
        post<UserAccount>('/users/employees', input),
      setStatus: (id: string, isActive: boolean) =>
        patch<{ ok: boolean }>(`/users/${id}/status`, { isActive }),
    },
    // ── delivery ──────────────────────────────────────────────────────────
    delivery: {
      zones: () => get<DeliveryZone[]>('/delivery/zones'),
      createZone: (input: UpsertDeliveryZoneInput) =>
        post<DeliveryZone>('/delivery/zones', input),
      updateZone: (id: string, input: UpsertDeliveryZoneInput) =>
        put<DeliveryZone>(`/delivery/zones/${id}`, input),
      deleteZone: (id: string) => del<{ ok: boolean }>(`/delivery/zones/${id}`),
    },
    // ── settings ──────────────────────────────────────────────────────────
    settings: {
      get: () => get<StoreSettings>('/settings'),
      update: (input: UpdateSettingsInput) => put<StoreSettings>('/settings', input),
    },
    // ── reports ───────────────────────────────────────────────────────────
    reports: {
      data: (type: ReportType, from?: string, to?: string) =>
        get<ReportData>('/reports', { type, from, to }),
      exportUrl: (type: ReportType, format: ReportFormat, from?: string, to?: string) => {
        const params = new URLSearchParams({ type, format });
        if (from) params.set('from', from);
        if (to) params.set('to', to);
        return `${opts.baseUrl.replace(/\/$/, '')}/reports/export?${params.toString()}`;
      },
      exportBlob: async (type: ReportType, format: ReportFormat, from?: string, to?: string) => {
        const res = await http.get('/reports/export', {
          params: { type, format, from, to },
          responseType: 'blob',
        });
        return res.data as Blob;
      },
    },
    // ── notifications ─────────────────────────────────────────────────────
    notifications: {
      list: (unreadOnly = false) =>
        get<AppNotification[]>('/notifications', unreadOnly ? { unreadOnly: 'true' } : undefined),
      unreadCount: () => get<{ count: number }>('/notifications/unread-count'),
      markRead: (id: string) => patch<{ ok: boolean }>(`/notifications/${id}/read`),
      markAllRead: () => patch<{ ok: boolean }>('/notifications/read-all'),
    },
    // ── audit ─────────────────────────────────────────────────────────────
    audit: {
      list: (q: PageQuery = {}) =>
        get<Paginated<ActivityLog>>('/activity-logs', q as Record<string, unknown>),
    },
  };
}

export type AldiafaApi = ReturnType<typeof createApiClient>;
export { axios };
