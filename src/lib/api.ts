"use client"

import type {
  BusinessSettings,
  Category,
  Customer,
  Product,
  Staff,
  StockMovement,
  Transaction,
} from "@/types/business"

export type BusinessData = {
  setupRequired: boolean
  categories: Category[]
  products: Product[]
  customers: Customer[]
  staff: Staff[]
  transactions: Transaction[]
  movements: StockMovement[]
  settings: BusinessSettings
}

async function json<T>(response: Response): Promise<T> {
  return (await response.json()) as T
}

export async function fetchBusinessData(): Promise<BusinessData> {
  const response = await fetch("/api/business", {
    cache: "no-store",
    credentials: "include",
  })

  if (!response.ok) {
    const error = (await response.json().catch(() => ({}))) as {
      error?: string
    }
    throw new Error(error?.error || "Gagal memuat data bisnis.")
  }

  return json<BusinessData>(response)
}

export async function mutateBusiness(action: string, payload: unknown) {
  const response = await fetch("/api/business", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ action, payload }),
    credentials: "include",
  })

  if (!response.ok) {
    const error = (await response.json().catch(() => ({}))) as {
      error?: string
    }
    throw new Error(error?.error || "Gagal menyimpan data.")
  }

  return json<{ ok?: boolean }>(response)
}

export type CheckoutPayload = {
  idempotencyKey: string
  items: { productId: string; quantity: number }[]
  paymentMethod: "cash" | "card" | "qris"
  paymentAmount?: number
  customerId?: string
  customerName?: string
  orderType: "dine-in" | "takeaway"
  tableNumber?: string
  discount: number
  tax: number
  cashier?: string
}

export async function fetchCheckout(payload: CheckoutPayload) {
  const response = await fetch("/api/pos/checkout", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
    credentials: "include",
  })

  if (!response.ok) {
    const error = (await response.json().catch(() => ({}))) as {
      error?: string
      details?: unknown
    }
    throw new Error(error?.error || "Checkout gagal.")
  }

  return json<unknown>(response)
}
