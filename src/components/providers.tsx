"use client"

import { useEffect } from "react"

import { QueryClientProvider } from "@tanstack/react-query"

import { ErrorState } from "@/components/shared/error-state"
import { queryClient } from "@/lib/query-client"
import { useBusinessQuery } from "@/hooks/use-business"
import { useBusinessStore } from "@/stores/business-store"

export function QueryProvider({ children }: { children: React.ReactNode }) {
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
}

/**
 * Keeps the Zustand business store in sync with TanStack Query, which fetches
 * real business data from `/api/business`. The store no longer performs its
 * own database fetch; this provider is the single data source for real sessions.
 */
export function BusinessDataProvider({
  children,
}: {
  children: React.ReactNode
}) {
  const ready = useBusinessStore((state) => state.ready)
  const { data, error, isPending, refetch } = useBusinessQuery({ enabled: true })

  useEffect(() => {
    // Sync whenever the query yields new data (first load, refetch after a
    // mutation, or recovery from a transient auth error).
    if (data) {
      useBusinessStore.setState({
        ...data,
        ready: true,
      })
      return
    }

    // Query settled without data — mark ready so the UI can render an empty
    // state instead of spinning forever.
    if (!isPending && !ready) {
      useBusinessStore.setState({
        setupRequired: false,
        categories: [],
        products: [],
        customers: [],
        staff: [],
        transactions: [],
        movements: [],
          settings: {
          businessName: "Warjok POS",
          address: "",
          phone: "",
          email: "",
          currency: "IDR",
          timezone: "Asia/Jakarta",
          taxRate: 0,
          memberDiscountRate: 0,
          lowStockThreshold: 0,
          receiptFooter: "Terima kasih • Warjok",
        },
        ready: true,
      })
    }
  }, [data, isPending, ready])

  if (error) {
    return (
      <ErrorState
        title="Data Warjok gagal dimuat"
        description={error.message || "Periksa koneksi lalu coba lagi."}
        onRetry={() => void refetch()}
      />
    )
  }

  return children
}

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <QueryProvider>
      <BusinessDataProvider>{children}</BusinessDataProvider>
    </QueryProvider>
  )
}
