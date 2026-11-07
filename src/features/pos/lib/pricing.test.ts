import { expect, test } from "bun:test"

import { computeTotals } from "./pricing"

test("computeTotals uses business tax and member rates", () => {
  expect(
    computeTotals(100_000, true, {
      taxRate: 0.1,
      memberDiscountRate: 0.2,
    })
  ).toEqual({
    subtotal: 100_000,
    discount: 20_000,
    tax: 8_000,
    total: 88_000,
  })
})

test("computeTotals does not apply rates that are not configured", () => {
  expect(computeTotals(100_000, true)).toEqual({
    subtotal: 100_000,
    discount: 0,
    tax: 0,
    total: 100_000,
  })
})
