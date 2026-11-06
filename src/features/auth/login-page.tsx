"use client";

import { zodResolver } from '@hookform/resolvers/zod'
import {
  CheckCircle2Icon,
  EyeIcon,
  EyeOffIcon,
  LockKeyholeIcon,
} from 'lucide-react'
import { useState } from 'react'
import Link from 'next/link'
import { useForm } from 'react-hook-form'
import { useRouter } from 'next/navigation'
import { useSearchParams } from 'next/navigation'
import { toast } from 'sonner'
import { z } from 'zod'

import { ThemeToggle } from '@/components/shared/theme-toggle'
import { Button } from '@/components/ui/button'
import { Logo } from '@/components/ui/logo'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { authClient } from '@/lib/auth-client'

const loginSchema = z.object({
  email: z
    .string()
    .trim()
    .min(1, 'Email wajib diisi')
    .refine(
      (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value),
      'Format email tidak valid',
    ),
  password: z.string().min(1, 'Kata sandi wajib diisi'),
})

type LoginValues = z.infer<typeof loginSchema>

const FEATURES = [
  'Katalog, stok, dan transaksi memakai satu sumber data.',
  'Laporan dan dashboard dihitung dari penjualan yang tersimpan.',
  'Semua data tersimpan di database Warjok.',
] as const

/**
 * Real sign-in screen powered by Neon Auth. Replaces the demo login flow.
 */
export function LoginPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [showPassword, setShowPassword] = useState(false)

  const from = searchParams.get('from')
  const redirectTo =
    from && from.startsWith('/') && from !== '/login'
      ? from
      : '/dashboard'

  const form = useForm<LoginValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
    },
  })

  const onSubmit = async (values: LoginValues) => {
    try {
      const result = await authClient.signIn.email(values)

      if (result?.error) {
        form.setError('password', {
          message: result.error.message || 'Email atau kata sandi salah.',
        })
        toast.error('Gagal masuk', {
          description: result.error.message || 'Email atau kata sandi salah.',
        })
        return
      }

      router.push(redirectTo)
      router.refresh()
    } catch (error) {
      form.setError('root', {
        message:
          error instanceof Error
            ? error.message
            : 'Gagal masuk. Silakan coba lagi.',
      })
      toast.error('Gagal masuk', {
        description: 'Silakan coba lagi.',
      })
    }
  }

  return (
    <div className="grid min-h-svh lg:grid-cols-2">
      <aside className="relative hidden flex-col justify-between overflow-hidden border-r border-sidebar-border bg-sidebar p-10 text-sidebar-foreground lg:flex">
        <div className="flex items-center gap-3">
          <Logo size="md" />
        </div>

        <div className="max-w-md space-y-6">
          <div className="space-y-3">
            <h1 className="text-3xl leading-tight font-semibold tracking-tight">
              Satu tempat untuk katalog, penjualan, dan stok.
            </h1>
            <p className="text-sm leading-relaxed text-sidebar-foreground/70">
              Warjok menyatukan terminal kasir, inventori, pelanggan, dan
              laporan tanpa berpindah aplikasi.
            </p>
          </div>
          <ul className="space-y-3">
            {FEATURES.map((feature) => (
              <li
                key={feature}
                className="flex items-start gap-2.5 text-sm text-sidebar-foreground/80"
              >
                <CheckCircle2Icon
                  aria-hidden="true"
                  className="mt-0.5 size-4 shrink-0 text-sidebar-primary"
                />
                {feature}
              </li>
            ))}
          </ul>
        </div>

        <p className="max-w-sm text-xs leading-relaxed text-sidebar-foreground/50">
          Warjok POS oleh Rynex.
        </p>
      </aside>

      <main className="relative flex items-center justify-center p-6 sm:p-10">
        <div className="absolute top-4 right-4">
          <ThemeToggle />
        </div>

        <div className="w-full max-w-sm">
          <div className="mb-8 flex items-center gap-3 lg:hidden">
            <Logo size="sm" />
          </div>

          <div className="space-y-2">
            <h1 className="text-2xl font-semibold tracking-tight">
              Masuk ke Warjok
            </h1>
            <p className="text-sm text-muted-foreground">
              Gunakan email dan kata sandi akun Anda untuk melanjutkan.
            </p>
          </div>

          <Form {...form}>
            <form
              onSubmit={form.handleSubmit(onSubmit)}
              method="post"
              className="mt-6 flex flex-col gap-4"
              noValidate
            >
              <FormField
                control={form.control}
                name="email"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Email</FormLabel>
                    <FormControl>
                      <Input
                        type="email"
                        inputMode="email"
                        autoComplete="username"
                        placeholder="nama@warjok.id"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="password"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Kata sandi</FormLabel>
                    <div className="relative">
                      <FormControl>
                        <Input
                          type={showPassword ? 'text' : 'password'}
                          autoComplete="current-password"
                          placeholder="••••••••"
                          className="pr-10"
                          {...field}
                        />
                      </FormControl>
                      <Button
                        type="button"
                        variant="ghost"
                        size="icon-xs"
                        className="absolute top-1/2 right-1 -translate-y-1/2"
                        aria-label={
                          showPassword
                            ? 'Sembunyikan kata sandi'
                            : 'Tampilkan kata sandi'
                        }
                        onClick={() => setShowPassword((value) => !value)}
                      >
                        {showPassword ? (
                          <EyeOffIcon aria-hidden="true" />
                        ) : (
                          <EyeIcon aria-hidden="true" />
                        )}
                      </Button>
                    </div>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <Button type="submit" className="mt-1 w-full">
                <LockKeyholeIcon aria-hidden="true" />
                Masuk
              </Button>
            </form>
          </Form>

          <p className="mt-6 text-center text-[11px] leading-relaxed text-muted-foreground">
            Belum punya akun?{' '}
            <Link
              href="/signup"
              className="font-medium text-foreground underline underline-offset-4 hover:text-primary"
            >
              Daftar
            </Link>
          </p>
        </div>
      </main>
    </div>
  )
}
