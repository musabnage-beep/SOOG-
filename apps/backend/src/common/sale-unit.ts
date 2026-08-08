import { SaleUnit } from '@prisma/client';

/** Fallback label for the base unit when a product doesn't override it. */
export const DEFAULT_PIECE_LABEL = 'حبة';

const STATIC_LABEL: Record<SaleUnit, string> = {
  [SaleUnit.PIECE]: DEFAULT_PIECE_LABEL,
  [SaleUnit.CARTON]: 'كرتون',
  [SaleUnit.HALF_KG]: 'نص كيلو',
  [SaleUnit.KG]: 'كيلو',
};

/** The subset of Product columns pricing depends on. */
export interface PricedProduct {
  price: unknown;
  discountPrice: unknown;
  sellByCarton: boolean;
  cartonPrice: unknown;
  halfKgPrice: unknown;
  kgPrice: unknown;
  pieceLabel?: string | null;
}

function positive(value: unknown): number | null {
  if (value == null) return null;
  const n = Number(value);
  return n > 0 ? n : null;
}

/**
 * Price of a single `unit` of the product, or null when the product isn't sold
 * that way. PIECE always resolves (discount price wins when it undercuts).
 */
export function unitPriceOf(product: PricedProduct, unit: SaleUnit): number | null {
  switch (unit) {
    case SaleUnit.CARTON:
      return product.sellByCarton ? positive(product.cartonPrice) : null;
    case SaleUnit.HALF_KG:
      return positive(product.halfKgPrice);
    case SaleUnit.KG:
      return positive(product.kgPrice);
    default: {
      const price = Number(product.price);
      const discount = positive(product.discountPrice);
      return discount != null && discount < price ? discount : price;
    }
  }
}

export function unitLabelOf(product: PricedProduct, unit: SaleUnit): string {
  if (unit === SaleUnit.PIECE) return product.pieceLabel?.trim() || DEFAULT_PIECE_LABEL;
  return STATIC_LABEL[unit];
}
