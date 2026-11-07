/** Tax and member-discount rules shared by the cart and checkout screens. */
export const TAX_RATE = 0
export const MEMBER_DISCOUNT_RATE = 0

export type PosTotals = {
  subtotal: number
  tax: number
  discount: number
  total: number
}

export type PosRates = {
  taxRate: number
  memberDiscountRate: number
}

/**
 * Round to whole rupiah so every displayed figure matches the receipt.
 * Rates come from the business settings so changes apply to the next order.
 */
export function computeTotals(
  subtotal: number,
  member: boolean,
  rates: Partial<PosRates> = {},
): PosTotals {
  const taxRate = rates.taxRate ?? TAX_RATE
  const memberDiscountRate = rates.memberDiscountRate ?? MEMBER_DISCOUNT_RATE
  const discount = member ? Math.round(subtotal * memberDiscountRate) : 0
  const tax = Math.round((subtotal - discount) * taxRate)

  return {
    subtotal,
    tax,
    discount,
    total: subtotal - discount + tax,
  }
}
