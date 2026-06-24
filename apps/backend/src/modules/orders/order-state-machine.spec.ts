import { OrderStatus } from '@prisma/client';
import { ORDER_TRANSITIONS, TERMINAL_STATUSES, canTransition } from './order-state-machine';

describe('order state machine', () => {
  it('allows the happy-path delivery lifecycle', () => {
    const path: OrderStatus[] = [
      OrderStatus.SUBMITTED,
      OrderStatus.UNDER_REVIEW,
      OrderStatus.APPROVED,
      OrderStatus.PREPARING,
      OrderStatus.READY,
      OrderStatus.OUT_FOR_DELIVERY,
      OrderStatus.DELIVERED,
    ];
    for (let i = 0; i < path.length - 1; i++) {
      expect(canTransition(path[i], path[i + 1])).toBe(true);
    }
  });

  it('allows the pickup branch from READY', () => {
    expect(canTransition(OrderStatus.READY, OrderStatus.PICKED_UP)).toBe(true);
  });

  it('allows rejection and the partial-availability confirmation loop', () => {
    expect(canTransition(OrderStatus.UNDER_REVIEW, OrderStatus.REJECTED)).toBe(true);
    expect(canTransition(OrderStatus.UNDER_REVIEW, OrderStatus.CONFIRMATION_REQUIRED)).toBe(true);
    expect(canTransition(OrderStatus.CONFIRMATION_REQUIRED, OrderStatus.UNDER_REVIEW)).toBe(true);
    expect(canTransition(OrderStatus.CONFIRMATION_REQUIRED, OrderStatus.CANCELLED)).toBe(true);
  });

  it('rejects illegal jumps', () => {
    expect(canTransition(OrderStatus.SUBMITTED, OrderStatus.DELIVERED)).toBe(false);
    expect(canTransition(OrderStatus.APPROVED, OrderStatus.REJECTED)).toBe(false);
    expect(canTransition(OrderStatus.PREPARING, OrderStatus.OUT_FOR_DELIVERY)).toBe(false);
    expect(canTransition(OrderStatus.READY, OrderStatus.DELIVERED)).toBe(false);
  });

  it('treats terminal statuses as dead ends', () => {
    for (const status of TERMINAL_STATUSES) {
      expect(ORDER_TRANSITIONS[status]).toHaveLength(0);
      for (const target of Object.values(OrderStatus)) {
        expect(canTransition(status, target)).toBe(false);
      }
    }
  });

  it('returns false for any unknown source defensively', () => {
    expect(canTransition('NONSENSE' as OrderStatus, OrderStatus.SUBMITTED)).toBe(false);
  });
});
