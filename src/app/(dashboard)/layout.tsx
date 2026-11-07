"use client"

import { useEffect } from "react"
import { usePathname, useRouter } from "next/navigation"

import { DashboardLayout } from "@/components/layout/dashboard-layout"
import { useRealUser } from "@/hooks/use-real-user"
import { useBusinessStore } from "@/stores/business-store"

export default function Layout({ children }: { children: React.ReactNode }) {
  const router = useRouter()
  const pathname = usePathname()
  const realUser = useRealUser(true)
  const role = realUser?.role
  const setupRequired = useBusinessStore((state) => state.setupRequired)

  useEffect(() => {
    if (!role) return
    if (role === "user" && pathname !== "/profile") {
      router.replace("/profile")
      return
    }
    if (role === "owner" && setupRequired && pathname !== "/setup") {
      router.replace("/setup")
    }
  }, [role, pathname, router, setupRequired])

  return <DashboardLayout>{children}</DashboardLayout>
}
