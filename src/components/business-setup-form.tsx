"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { Loader2Icon, StoreIcon } from "lucide-react"
import { z } from "zod"

import { Alert, AlertDescription } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { queryClient } from "@/lib/query-client"
import { BUSINESS_QUERY_KEY } from "@/hooks/use-business"
import { useBusinessStore } from "@/stores/business-store"

const setupSchema = z.object({
  businessName: z.string().trim().min(2, "Nama bisnis minimal 2 karakter").max(120),
  storeName: z.string().trim().min(2, "Nama toko minimal 2 karakter").max(120),
  address: z.string().trim().max(300, "Alamat maksimal 300 karakter"),
  phone: z.string().trim().max(32, "Nomor telepon maksimal 32 karakter"),
  email: z.union([
    z.literal(""),
    z.string().trim().email("Format email tidak valid").max(254),
  ]),
})

type SetupValues = z.infer<typeof setupSchema>

export function BusinessSetupForm() {
  const router = useRouter()
  const [checkAttempt, setCheckAttempt] = useState(0)
  const [status, setStatus] = useState<
    "loading" | "ready" | "not-owner" | "error"
  >("loading")
  const [formError, setFormError] = useState("")
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<SetupValues>({
    resolver: zodResolver(setupSchema),
    defaultValues: {
      businessName: "",
      storeName: "Toko Utama",
      address: "",
      phone: "",
      email: "",
    },
  })

  useEffect(() => {
    let active = true
    fetch("/api/setup", { cache: "no-store", credentials: "include" })
      .then(async (response) => {
        if (!response.ok) throw new Error("Status setup tidak dapat dimuat.")
        return response.json()
      })
      .then((data: { setupRequired: boolean; canSetup: boolean }) => {
        if (!active) return
        if (!data.canSetup) {
          setStatus("not-owner")
          return
        }
        if (!data.setupRequired) {
          router.replace("/dashboard")
          return
        }
        setStatus("ready")
      })
      .catch(() => {
        if (active) setStatus("error")
      })
    return () => {
      active = false
    }
  }, [checkAttempt, router])

  const onSubmit = async (values: SetupValues) => {
    setFormError("")
    try {
      const response = await fetch("/api/setup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify(values),
      })
      const result = await response.json().catch(() => ({}))
      if (!response.ok) {
        setFormError(result.error || "Setup bisnis gagal disimpan.")
        return
      }

      useBusinessStore.setState({ setupRequired: false, ready: false })
      queryClient.removeQueries({ queryKey: BUSINESS_QUERY_KEY })
      router.replace("/dashboard")
      router.refresh()
    } catch (error) {
      setFormError(
        error instanceof Error
          ? error.message
          : "Setup bisnis gagal. Periksa koneksi lalu coba lagi."
      )
    }
  }

  if (status === "loading") {
    return (
      <div className="flex items-center justify-center py-16 text-muted-foreground">
        <Loader2Icon className="mr-2 size-4 animate-spin" />
        Memeriksa konfigurasi Warjok...
      </div>
    )
  }

  if (status === "error") {
    return (
      <div className="space-y-4">
        <Alert variant="destructive">
          <AlertDescription>
            Status setup tidak dapat dimuat. Periksa koneksi database, lalu
            coba periksa kembali.
          </AlertDescription>
        </Alert>
        <Button
          variant="outline"
          className="w-full"
          onClick={() => {
            setStatus("loading")
            setCheckAttempt((attempt) => attempt + 1)
          }}
        >
          Coba lagi
        </Button>
      </div>
    )
  }

  if (status === "not-owner") {
    return (
      <div className="space-y-4">
        <Alert variant="warning">
          <AlertDescription>
            Hanya akun pemilik yang dapat menyiapkan bisnis. Masuk dengan akun
            pemilik Warjok atau hubungi pemilik bisnis.
          </AlertDescription>
        </Alert>
        <Button
          variant="outline"
          className="w-full"
          onClick={() => router.replace("/profile")}
        >
          Kembali
        </Button>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="space-y-2">
        <div className="flex size-11 items-center justify-center rounded-xl bg-primary/10 text-primary">
          <StoreIcon aria-hidden="true" className="size-5" />
        </div>
        <h1 className="text-2xl font-semibold tracking-tight">
          Siapkan bisnis Warjok
        </h1>
        <p className="text-sm leading-relaxed text-muted-foreground">
          Isi informasi dasar untuk mulai menggunakan POS. Akun Anda akan
          tercatat sebagai pemilik. Kategori dan produk tidak dibuat otomatis;
          Anda dapat menambahkannya setelah setup selesai.
        </p>
      </div>

      {formError && (
        <Alert variant="destructive">
          <AlertDescription>{formError}</AlertDescription>
        </Alert>
      )}

      <form onSubmit={handleSubmit(onSubmit)} method="post" noValidate>
        <FieldGroup className="gap-5">
          <Field data-invalid={!!errors.businessName}>
            <FieldLabel htmlFor="businessName">Nama bisnis</FieldLabel>
            <Input
              id="businessName"
              autoComplete="organization"
              placeholder="Contoh: Warjok"
              aria-invalid={!!errors.businessName}
              {...register("businessName")}
            />
            <FieldError errors={[errors.businessName]} />
          </Field>
          <Field data-invalid={!!errors.storeName}>
            <FieldLabel htmlFor="storeName">Nama toko utama</FieldLabel>
            <Input
              id="storeName"
              autoComplete="organization"
              placeholder="Contoh: Toko Utama"
              aria-invalid={!!errors.storeName}
              {...register("storeName")}
            />
            <FieldError errors={[errors.storeName]} />
          </Field>
          <Field data-invalid={!!errors.address}>
            <FieldLabel htmlFor="address">Alamat (opsional)</FieldLabel>
            <Textarea
              id="address"
              autoComplete="street-address"
              rows={2}
              aria-invalid={!!errors.address}
              {...register("address")}
            />
            <FieldError errors={[errors.address]} />
          </Field>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field data-invalid={!!errors.phone}>
              <FieldLabel htmlFor="phone">Nomor telepon (opsional)</FieldLabel>
              <Input
                id="phone"
                type="tel"
                autoComplete="tel"
                aria-invalid={!!errors.phone}
                {...register("phone")}
              />
              <FieldError errors={[errors.phone]} />
            </Field>
            <Field data-invalid={!!errors.email}>
              <FieldLabel htmlFor="email">Email bisnis (opsional)</FieldLabel>
              <Input
                id="email"
                type="email"
                autoComplete="email"
                aria-invalid={!!errors.email}
                {...register("email")}
              />
              <FieldError errors={[errors.email]} />
            </Field>
          </div>
          <Button type="submit" className="w-full" disabled={isSubmitting}>
            {isSubmitting && <Loader2Icon className="animate-spin" />}
            {isSubmitting ? "Menyiapkan..." : "Buat bisnis"}
          </Button>
        </FieldGroup>
      </form>
    </div>
  )
}
