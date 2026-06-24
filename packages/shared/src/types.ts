// ───────────────────────────────────────────────────────────────────────────
// ALDIAFAH shared domain types — mirror of the NestJS backend contract.
// ───────────────────────────────────────────────────────────────────────────

export type RoleName = 'CUSTOMER' | 'EMPLOYEE' | 'ADMIN';

export type OrderStatus =
  | 'SUBMITTED'
  | 'UNDER_REVIEW'
  | 'CONFIRMATION_REQUIRED'
  | 'APPROVED'
  | 'PREPARING'
  | 'READY'
  | 'OUT_FOR_DELIVERY'
  | 'DELIVERED'
  | 'PICKED_UP'
  | 'REJECTED'
  | 'CANCELLED';

export type FulfillmentType = 'DELIVERY' | 'PICKUP';
export type OrderItemAvailability = 'AVAILABLE' | 'UNAVAILABLE';
export type StockStatus = 'IN_STOCK' | 'LOW_STOCK' | 'OUT_OF_STOCK';
export type InventoryLogType = 'STOCK_IN' | 'STOCK_OUT' | 'SOLD' | 'ADJUST';
export type NotificationChannel = 'PUSH' | 'IN_APP' | 'EMAIL';
export type OtpPurpose = 'REGISTRATION' | 'LOGIN' | 'PASSWORD_RESET';
export type ReportType = 'SALES' | 'ORDERS' | 'INVENTORY' | 'CUSTOMERS' | 'EMPLOYEES';
export type ReportFormat = 'PDF' | 'EXCEL' | 'CSV';

export type NotificationType =
  | 'ORDER_SUBMITTED'
  | 'ORDER_UNDER_REVIEW'
  | 'CONFIRMATION_REQUIRED'
  | 'ORDER_APPROVED'
  | 'ORDER_REJECTED'
  | 'ORDER_PREPARING'
  | 'ORDER_READY'
  | 'ORDER_OUT_FOR_DELIVERY'
  | 'ORDER_DELIVERED'
  | 'ORDER_PICKED_UP'
  | 'LOW_STOCK'
  | 'OUT_OF_STOCK'
  | 'SYSTEM';

export interface AuthUser {
  id: string;
  fullName: string;
  email: string | null;
  phone: string | null;
  role: RoleName;
}

export interface AuthResult {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: AuthUser;
}

export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface Paginated<T> {
  items: T[];
  meta: PaginationMeta;
}

export interface Category {
  id: string;
  nameAr: string;
  nameEn: string;
  slug: string;
  icon: string | null;
  sortOrder: number;
  isActive: boolean;
}

export interface ProductImage {
  id: string;
  productId?: string;
  s3Key?: string;
  url: string;
  isMain: boolean;
  sortOrder: number;
}

export interface Product {
  id: string;
  nameAr: string;
  nameEn: string;
  descriptionAr: string | null;
  descriptionEn: string | null;
  price: string | number;
  discountPrice: string | number | null;
  sku: string;
  barcode: string | null;
  weightGrams?: number | null;
  quantity: number;
  lowStockThreshold?: number;
  stockStatus: StockStatus;
  tags?: string[];
  isActive: boolean;
  category?: Category;
  categoryId?: string;
  images: ProductImage[];
  createdAt?: string;
  updatedAt?: string;
}

export interface Address {
  id: string;
  userId?: string;
  label: string | null;
  country: string;
  city: string;
  district: string;
  street: string;
  postalCode: string | null;
  latitude: number;
  longitude: number;
  notes: string | null;
  isDefault: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface OrderItem {
  id: string;
  orderId: string;
  productId: string;
  nameAr: string;
  nameEn: string;
  unitPrice: string | number;
  quantity: number;
  lineTotal: string | number;
  availability: OrderItemAvailability;
}

export interface OrderStatusHistory {
  id: string;
  orderId: string;
  status: OrderStatus;
  note: string | null;
  changedBy: string | null;
  createdAt: string;
}

export interface Order {
  id: string;
  orderNumber: string;
  userId: string;
  status: OrderStatus;
  fulfillmentType: FulfillmentType;
  addressId: string | null;
  address?: Address | null;
  subtotal: string | number;
  deliveryFee: string | number;
  discountTotal: string | number;
  total: string | number;
  distanceMeters: number | null;
  etaMinutes: number | null;
  customerNote: string | null;
  rejectionReason: string | null;
  reviewedById: string | null;
  submittedAt: string;
  approvedAt: string | null;
  deliveredAt: string | null;
  createdAt: string;
  updatedAt: string;
  user?: { id: string; fullName: string; phone: string | null; email: string | null };
  items: OrderItem[];
  statusHistory?: OrderStatusHistory[];
  _count?: { items: number };
}

export interface UserAccount {
  id: string;
  fullName: string;
  email: string | null;
  phone: string | null;
  role: RoleName;
  isActive: boolean;
  createdAt: string;
  _count?: { orders?: number; reviewedOrders?: number };
}

export interface InventoryLog {
  id: string;
  productId: string;
  type: InventoryLogType;
  quantityDelta: number;
  quantityBefore: number;
  quantityAfter: number;
  reason: string | null;
  actor?: { id: string; fullName: string } | null;
  createdAt: string;
}

export interface DeliveryZone {
  id: string;
  name: string;
  minRadiusM: number;
  maxRadiusM: number;
  fee: string | number;
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface StoreSettings {
  id: string;
  storeName: string;
  storeLatitude: number;
  storeLongitude: number;
  freeDeliveryRadiusM: number;
  deliveryRadiusM: number;
  baseDeliveryFee: string | number;
  currency: string;
  avgSpeedKmh: number;
  updatedAt: string;
}

export interface AppNotification {
  id: string;
  userId: string;
  type: NotificationType;
  channel: NotificationChannel;
  title: string;
  body: string;
  payload: Record<string, unknown> | null;
  isRead: boolean;
  createdAt: string;
}

export interface ActivityLog {
  id: string;
  userId: string | null;
  user?: { id: string; fullName: string; email: string | null } | null;
  action: string;
  entity: string;
  entityId: string | null;
  ip: string | null;
  oldValue: Record<string, unknown> | null;
  newValue: Record<string, unknown> | null;
  createdAt: string;
}

export interface EmployeeDashboard {
  pending: number;
  underReview: number;
  lowStock: number;
  recent: Array<{
    id: string;
    orderNumber: string;
    status: OrderStatus;
    submittedAt: string;
    user: { fullName: string };
    _count: { items: number };
  }>;
}

export interface AdminDashboard {
  totalRevenue: number;
  monthRevenue: number;
  orders: number;
  customers: number;
  employees: number;
  products: number;
  ordersByStatus: Partial<Record<OrderStatus, number>>;
}

export interface DailySalesPoint {
  day: string;
  revenue: number;
  orders: number;
}

export interface TopProduct {
  productId: string;
  nameAr: string;
  nameEn: string;
  unitsSold: number;
  revenue: number;
}

export interface ReportData {
  title: string;
  columns: string[];
  rows: Array<Array<string | number>>;
}

// ── DTO input shapes ─────────────────────────────────────────────────────────

export interface LoginInput {
  email?: string;
  phone?: string;
  password: string;
}

export interface CreateProductInput {
  nameAr: string;
  nameEn: string;
  descriptionAr?: string;
  descriptionEn?: string;
  categoryId: string;
  price: number;
  discountPrice?: number;
  sku: string;
  barcode?: string;
  weightGrams?: number;
  quantity?: number;
  lowStockThreshold?: number;
  tags?: string[];
  isActive?: boolean;
}

export type UpdateProductInput = Partial<CreateProductInput>;

export interface CreateCategoryInput {
  nameAr: string;
  nameEn: string;
  slug: string;
  icon?: string;
  sortOrder?: number;
  isActive?: boolean;
}

export type UpdateCategoryInput = Partial<CreateCategoryInput>;

export interface CreateEmployeeInput {
  fullName: string;
  email: string;
  phone?: string;
  password: string;
}

export interface AdjustStockInput {
  type: InventoryLogType;
  quantityDelta: number;
  reason?: string;
}

export interface UpsertDeliveryZoneInput {
  name: string;
  minRadiusM: number;
  maxRadiusM: number;
  fee: number;
  isActive?: boolean;
}

export interface UpdateSettingsInput {
  storeName?: string;
  storeLatitude?: number;
  storeLongitude?: number;
  freeDeliveryRadiusM?: number;
  deliveryRadiusM?: number;
  baseDeliveryFee?: number;
  currency?: string;
  avgSpeedKmh?: number;
}

export interface ProductQuery {
  page?: number;
  limit?: number;
  search?: string;
  categoryId?: string;
  categorySlug?: string;
  minPrice?: number;
  maxPrice?: number;
  sort?: 'newest' | 'price_asc' | 'price_desc' | 'name';
  inStock?: string;
}

export interface OrderQuery {
  page?: number;
  limit?: number;
  search?: string;
  status?: OrderStatus;
}

export interface PageQuery {
  page?: number;
  limit?: number;
  search?: string;
}
