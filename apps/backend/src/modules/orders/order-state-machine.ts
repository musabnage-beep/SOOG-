import { OrderStatus } from '@prisma/client';

/**
 * Allowed order status transitions. The order lifecycle is:
 *
 * SUBMITTED → UNDER_REVIEW → APPROVED → PREPARING → READY → OUT_FOR_DELIVERY → DELIVERED
 *                          ↘ REJECTED                              ↘ PICKED_UP (pickup)
 *                          ↘ CONFIRMATION_REQUIRED → UNDER_REVIEW (customer continues)
 *                                                  ↘ CANCELLED   (customer cancels)
 */
export const ORDER_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  SUBMITTED: [OrderStatus.UNDER_REVIEW, OrderStatus.CANCELLED],
  UNDER_REVIEW: [OrderStatus.APPROVED, OrderStatus.REJECTED, OrderStatus.CONFIRMATION_REQUIRED],
  CONFIRMATION_REQUIRED: [OrderStatus.UNDER_REVIEW, OrderStatus.CANCELLED],
  APPROVED: [OrderStatus.PREPARING],
  PREPARING: [OrderStatus.READY],
  READY: [OrderStatus.OUT_FOR_DELIVERY, OrderStatus.PICKED_UP],
  OUT_FOR_DELIVERY: [OrderStatus.DELIVERED],
  DELIVERED: [],
  PICKED_UP: [],
  REJECTED: [],
  CANCELLED: [],
};

export const TERMINAL_STATUSES: OrderStatus[] = [
  OrderStatus.DELIVERED,
  OrderStatus.PICKED_UP,
  OrderStatus.REJECTED,
  OrderStatus.CANCELLED,
];

export function canTransition(from: OrderStatus, to: OrderStatus): boolean {
  return ORDER_TRANSITIONS[from]?.includes(to) ?? false;
}
