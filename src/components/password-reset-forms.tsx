"use client"

import { useState } from "react"
import Link from "next/link"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { Loader2Icon, MailIcon, SaveIcon } from "lucide-react"
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
import { authClient } from "@/lib/auth-client"

const emailSchema = z.object({
  email: z
    .string()
    .trim()
    .min(1, "Email wajib diisi")
    .refine(
      (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value),
      "Format email tidak valid"
    ),
})

const passwordSchema = z
  .object({
    password: z.string().min(8, "Kata sandi minimal 8 karakter"),
    confirmPassword: z.string().min(1, "Konfirmasi kata sandi wajib diisi"),
  })
  .refine((values) => values.password === values.confirmPassword, {
    message: "Konfirmasi kata sandi tidak cocok",
    path: ["confirmPassword"],
  })

type EmailValues = z.infer<typeof emailSchema>
type PasswordValues = z.infer<typeof passwordSchema>

export function ForgotPasswordForm() {
  const [formError, setFormError] = useState("")
  const [submitted, setSubmitted] = useState(false)
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<EmailValues>({
    resolver: zodResolver(emailSchema),
    defaultValues: { email: "" },
  })

  const onSubmit = async ({ email }: EmailValues) => {
    setFormError("")
    try {
      const result = await authClient.requestPasswordReset({
        email,
        redirectTo: `${window.location.origin}/reset-password`,
      })
      if (result.error) {
        setFormError(result.error.message || "Permintaan reset gagal.")
        return
      }
      setSubmitted(true)
    } catch (error) {
      setFormError(
        error instanceof Error
          ? error.message
          : "Permintaan reset gagal. Silakan coba lagi."
      )
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="space-y-1.5 text-center">
        <h1 className="text-2xl font-semibold tracking-tight">
          Lupa kata sandi?
        </h1>
        <p className="text-sm text-balance text-muted-foreground">
          Masukkan email akun Anda. Jika terdaftar, kami akan mengirim tautan
          untuk mengatur kata sandi baru.
        </p>
      </div>

      {formError && (
        <Alert variant="destructive">
          <AlertDescription>{formError}</AlertDescription>
        </Alert>
      )}
      {submitted ? (
        <Alert variant="success">
          <AlertDescription>
            Jika email tersebut terdaftar, tautan reset kata sandi telah
            dikirim. Periksa kotak masuk dan folder spam.
          </AlertDescription>
        </Alert>
      ) : (
        <form onSubmit={handleSubmit(onSubmit)} method="post" noValidate>
          <FieldGroup className="gap-5">
            <Field data-invalid={!!errors.email}>
              <FieldLabel htmlFor="email">Email</FieldLabel>
              <Input
                id="email"
                type="email"
                inputMode="email"
                autoComplete="email"
                placeholder="nama@warjok.id"
                aria-invalid={!!errors.email}
                {...register("email")}
              />
              <FieldError errors={[errors.email]} />
            </Field>
            <Button type="submit" className="w-full" disabled={isSubmitting}>
              {isSubmitting ? (
                <Loader2Icon className="animate-spin" />
              ) : (
                <MailIcon />
              )}
              {isSubmitting ? "Mengirim..." : "Kirim tautan reset"}
            </Button>
          </FieldGroup>
        </form>
      )}

      <p className="text-center text-sm text-muted-foreground">
        <Link
          href="/login"
          className="font-medium text-foreground underline underline-offset-4 hover:text-primary"
        >
          Kembali ke halaman masuk
        </Link>
      </p>
    </div>
  )
}

export function ResetPasswordForm({ token }: { token: string }) {
  const [formError, setFormError] = useState("")
  const [submitted, setSubmitted] = useState(false)
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<PasswordValues>({
    resolver: zodResolver(passwordSchema),
    defaultValues: { password: "", confirmPassword: "" },
  })

  const onSubmit = async ({ password }: PasswordValues) => {
    setFormError("")
    try {
      const result = await authClient.resetPassword({
        newPassword: password,
        token,
      })
      if (result.error) {
        setFormError(result.error.message || "Reset kata sandi gagal.")
        return
      }
      setSubmitted(true)
    } catch (error) {
      setFormError(
        error instanceof Error
          ? error.message
          : "Reset kata sandi gagal. Silakan coba lagi."
      )
    }
  }

  if (!token) {
    return (
      <div className="flex flex-col gap-6 text-center">
        <h1 className="text-2xl font-semibold tracking-tight">
          Tautan reset tidak valid
        </h1>
        <p className="text-sm text-muted-foreground">
          Minta tautan reset baru dari halaman lupa kata sandi.
        </p>
        <Link
          href="/forgot-password"
          className="text-sm font-medium underline underline-offset-4"
        >
          Minta tautan baru
        </Link>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="space-y-1.5 text-center">
        <h1 className="text-2xl font-semibold tracking-tight">
          Atur kata sandi baru
        </h1>
        <p className="text-sm text-muted-foreground">
          Gunakan minimal 8 karakter.
        </p>
      </div>

      {formError && (
        <Alert variant="destructive">
          <AlertDescription>{formError}</AlertDescription>
        </Alert>
      )}
      {submitted ? (
        <>
          <Alert variant="success">
            <AlertDescription>
              Kata sandi berhasil diperbarui. Silakan masuk dengan kata sandi
              baru Anda.
            </AlertDescription>
          </Alert>
          <Button asChild className="w-full">
            <Link href="/login">Masuk</Link>
          </Button>
        </>
      ) : (
        <form onSubmit={handleSubmit(onSubmit)} method="post" noValidate>
          <FieldGroup className="gap-5">
            <Field data-invalid={!!errors.password}>
              <FieldLabel htmlFor="password">Kata sandi baru</FieldLabel>
              <Input
                id="password"
                type="password"
                autoComplete="new-password"
                aria-invalid={!!errors.password}
                {...register("password")}
              />
              <FieldError errors={[errors.password]} />
            </Field>
            <Field data-invalid={!!errors.confirmPassword}>
              <FieldLabel htmlFor="confirmPassword">
                Konfirmasi kata sandi
              </FieldLabel>
              <Input
                id="confirmPassword"
                type="password"
                autoComplete="new-password"
                aria-invalid={!!errors.confirmPassword}
                {...register("confirmPassword")}
              />
              <FieldError errors={[errors.confirmPassword]} />
            </Field>
            <Button type="submit" className="w-full" disabled={isSubmitting}>
              {isSubmitting ? (
                <Loader2Icon className="animate-spin" />
              ) : (
                <SaveIcon />
              )}
              {isSubmitting ? "Menyimpan..." : "Simpan kata sandi baru"}
            </Button>
          </FieldGroup>
        </form>
      )}
    </div>
  )
}
