import type {
  OrderStatus,
  StockStatus,
  FulfillmentType,
  PaymentMethod,
  PaymentStatus,
  InventoryLogType,
  ReportType,
  RoleName,
} from './types';

export const ORDER_STATUS_LABEL_AR: Record<OrderStatus, string> = {
  SUBMITTED: 'بانتظار المراجعة',
  UNDER_REVIEW: 'قيد المراجعة',
  CONFIRMATION_REQUIRED: 'بحاجة لتأكيد العميل',
  APPROVED: 'تمت الموافقة',
  PREPARING: 'قيد التجهيز',
  READY: 'جاهز',
  OUT_FOR_DELIVERY: 'قيد التوصيل',
  DELIVERED: 'تم التوصيل',
  PICKED_UP: 'تم الاستلام',
  REJECTED: 'مرفوض',
  CANCELLED: 'ملغى',
};

// tailwind-ish badge tone per status
export const ORDER_STATUS_TONE: Record<OrderStatus, string> = {
  SUBMITTED: 'bg-amber-100 text-amber-800',
  UNDER_REVIEW: 'bg-blue-100 text-blue-800',
  CONFIRMATION_REQUIRED: 'bg-orange-100 text-orange-800',
  APPROVED: 'bg-emerald-100 text-emerald-800',
  PREPARING: 'bg-indigo-100 text-indigo-800',
  READY: 'bg-cyan-100 text-cyan-800',
  OUT_FOR_DELIVERY: 'bg-violet-100 text-violet-800',
  DELIVERED: 'bg-green-100 text-green-800',
  PICKED_UP: 'bg-green-100 text-green-800',
  REJECTED: 'bg-red-100 text-red-800',
  CANCELLED: 'bg-gray-200 text-gray-700',
};

export const STOCK_STATUS_LABEL_AR: Record<StockStatus, string> = {
  IN_STOCK: 'متوفر',
  LOW_STOCK: 'مخزون منخفض',
  OUT_OF_STOCK: 'نفد المخزون',
};

export const STOCK_STATUS_TONE: Record<StockStatus, string> = {
  IN_STOCK: 'bg-green-100 text-green-800',
  LOW_STOCK: 'bg-amber-100 text-amber-800',
  OUT_OF_STOCK: 'bg-red-100 text-red-800',
};

export const FULFILLMENT_LABEL_AR: Record<FulfillmentType, string> = {
  DELIVERY: 'توصيل',
  PICKUP: 'استلام من المتجر',
};

export const PAYMENT_METHOD_LABEL_AR: Record<PaymentMethod, string> = {
  COD: 'الدفع عند الاستلام',
  CARD: 'دفع إلكتروني',
};

export const PAYMENT_STATUS_LABEL_AR: Record<PaymentStatus, string> = {
  PENDING: 'بانتظار الدفع',
  PAID: 'مدفوع',
  FAILED: 'فشل الدفع',
  REFUNDED: 'مُسترجع',
};

export const PAYMENT_STATUS_TONE: Record<PaymentStatus, string> = {
  PENDING: 'bg-amber-100 text-amber-800',
  PAID: 'bg-green-100 text-green-800',
  FAILED: 'bg-red-100 text-red-800',
  REFUNDED: 'bg-gray-200 text-gray-700',
};

export const INVENTORY_TYPE_LABEL_AR: Record<InventoryLogType, string> = {
  STOCK_IN: 'إدخال مخزون',
  STOCK_OUT: 'إخراج مخزون',
  SOLD: 'مبيعات',
  ADJUST: 'تسوية',
};

export const REPORT_TYPE_LABEL_AR: Record<ReportType, string> = {
  SALES: 'تقرير المبيعات',
  ORDERS: 'تقرير الطلبات',
  INVENTORY: 'تقرير المخزون',
  CUSTOMERS: 'تقرير العملاء',
  EMPLOYEES: 'تقرير الموظفين',
};

export const ROLE_LABEL_AR: Record<RoleName, string> = {
  CUSTOMER: 'عميل',
  EMPLOYEE: 'موظف',
  ADMIN: 'مدير',
};

// statuses staff can advance to via /orders/:id/status
export const ADVANCEABLE_STATUSES: OrderStatus[] = [
  'PREPARING',
  'READY',
  'OUT_FOR_DELIVERY',
  'DELIVERED',
  'PICKED_UP',
];

export const TERMINAL_STATUSES: OrderStatus[] = [
  'DELIVERED',
  'PICKED_UP',
  'REJECTED',
  'CANCELLED',
];

// Order state machine — valid forward transitions (mirrors backend).
export const ORDER_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  SUBMITTED: ['UNDER_REVIEW', 'CANCELLED'],
  UNDER_REVIEW: ['APPROVED', 'REJECTED', 'CONFIRMATION_REQUIRED'],
  CONFIRMATION_REQUIRED: ['UNDER_REVIEW', 'CANCELLED'],
  APPROVED: ['PREPARING'],
  PREPARING: ['READY'],
  READY: ['OUT_FOR_DELIVERY', 'PICKED_UP'],
  OUT_FOR_DELIVERY: ['DELIVERED'],
  DELIVERED: [],
  PICKED_UP: [],
  REJECTED: [],
  CANCELLED: [],
};

/** Forward statuses reachable via the /orders/:id/status endpoint only. */
export function advanceTargets(status: OrderStatus): OrderStatus[] {
  return ORDER_TRANSITIONS[status].filter((s) => ADVANCEABLE_STATUSES.includes(s));
}

export const BRAND = {
  primary: '#166534',
  secondary: '#22C55E',
  cream: '#FFF8E7',
  gold: '#D4AF37',
  dark: '#111827',
};
