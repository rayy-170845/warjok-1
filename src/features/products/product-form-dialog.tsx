"use client";

import { zodResolver } from '@hookform/resolvers/zod'
import { useEffect } from 'react'
import Link from 'next/link'
import { useForm } from 'react-hook-form'
import { z } from 'zod'

import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import type { Category, Product } from '@/types/business'

const productSchema = z.object({
  name: z.string().trim().min(1, 'Nama produk wajib diisi'),
  sku: z.string().trim().min(1, 'SKU wajib diisi'),
  barcode: z.string().trim().optional(),
  categoryId: z.string().min(1, 'Pilih kategori'),
  price: z.number().min(1, 'Harga jual harus lebih dari 0'),
  cost: z.number().min(0, 'Harga modal tidak boleh negatif'),
  stock: z.number().int('Stok harus bilangan bulat').min(0, 'Stok tidak boleh negatif'),
  minStock: z
    .number()
    .int('Stok minimum harus bilangan bulat')
    .min(0, 'Stok minimum tidak boleh negatif'),
  unit: z.string().trim().min(1, 'Satuan wajib diisi'),
  imageUrl: z.string().trim().optional(),
  status: z.enum(['active', 'archived']),
})

export type ProductFormValues = z.infer<typeof productSchema>

export function ProductFormDialog({
  open,
  onOpenChange,
  product,
  categories,
  onSubmit,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  product?: Product | null
  categories: readonly Category[]
  onSubmit: (values: ProductFormValues) => boolean
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[92svh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{product ? 'Edit produk' : 'Tambah produk'}</DialogTitle>
          <DialogDescription>
            {product
              ? 'Perbarui informasi produk. Perubahan langsung dipakai di POS.'
              : 'Produk baru langsung tersedia di katalog POS setelah disimpan.'}
          </DialogDescription>
        </DialogHeader>

        <ProductFormBody
          key={product?.id ?? 'new'}
          product={product}
          categories={categories}
          onCancel={() => onOpenChange(false)}
          onSubmit={(values) => {
            if (onSubmit(values)) onOpenChange(false)
          }}
        />
      </DialogContent>
    </Dialog>
  )
}

function ProductFormBody({
  product,
  categories,
  onCancel,
  onSubmit,
}: {
  product?: Product | null
  categories: readonly Category[]
  onCancel: () => void
  onSubmit: (values: ProductFormValues) => void
}) {
  const form = useForm<ProductFormValues>({
    resolver: zodResolver(productSchema),
    defaultValues: {
      name: product?.name ?? '',
      sku: product?.sku ?? '',
      barcode: product?.barcode ?? '',
      categoryId: product?.categoryId ?? categories[0]?.id ?? '',
      price: product?.price ?? 0,
      cost: product?.cost ?? 0,
      stock: product?.stock ?? 0,
      minStock: product?.minStock ?? 5,
      unit: product?.unit ?? 'pcs',
      imageUrl: product?.imageUrl ?? '',
      status: product?.status ?? 'active',
    },
  })

  // Keep the category valid if the list changes while the dialog is open.
  useEffect(() => {
    if (categories.length === 0) return
    if (!categories.some((category) => category.id === form.getValues('categoryId'))) {
      form.setValue('categoryId', categories[0]!.id)
    }
  }, [categories, form])

  return (
    <Form {...form}>
      <form
        onSubmit={form.handleSubmit(onSubmit)}
        className="flex flex-col gap-4"
      >
        <div className="grid gap-4 sm:grid-cols-2">
          <FormField
            control={form.control}
            name="name"
            render={({ field }) => (
              <FormItem className="sm:col-span-2">
                <FormLabel>Nama produk</FormLabel>
                <FormControl>
                  <Input placeholder="Contoh: Butter Croissant" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="sku"
            render={({ field }) => (
              <FormItem>
                <FormLabel>SKU</FormLabel>
                <FormControl>
                  <Input placeholder="BAK-001" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="barcode"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Barcode</FormLabel>
                <FormControl>
                  <Input placeholder="Opsional" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="categoryId"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Kategori</FormLabel>
                <Select
                  value={field.value}
                  onValueChange={field.onChange}
                  disabled={categories.length === 0}
                >
                  <FormControl>
                    <SelectTrigger>
                      <SelectValue
                        placeholder={
                          categories.length === 0
                            ? 'Belum ada kategori'
                            : 'Pilih kategori'
                        }
                      />
                    </SelectTrigger>
                  </FormControl>
                  <SelectContent>
                    {categories.map((category) => (
                      <SelectItem key={category.id} value={category.id}>
                        {category.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {categories.length === 0 && (
                  <FormDescription>
                    Buat kategori terlebih dahulu di{' '}
                    <Link
                      href="/categories"
                      className="font-medium text-foreground underline underline-offset-4"
                    >
                      halaman Kategori
                    </Link>
                    .
                  </FormDescription>
                )}
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="status"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Status</FormLabel>
                <Select value={field.value} onValueChange={field.onChange}>
                  <FormControl>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                  </FormControl>
                  <SelectContent>
                    <SelectItem value="active">Aktif</SelectItem>
                    <SelectItem value="archived">Diarsipkan</SelectItem>
                  </SelectContent>
                </Select>
                <FormDescription>
                  Produk diarsipkan tidak tampil di POS.
                </FormDescription>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="price"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Harga jual (Rp)</FormLabel>
                <FormControl>
                  <Input
                    type="number"
                    min={0}
                    step={1000}
                    inputMode="numeric"
                    value={field.value}
                    onChange={(event) =>
                      field.onChange(
                        event.target.value === '' ? 0 : Number(event.target.value),
                      )
                    }
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="cost"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Harga modal (Rp)</FormLabel>
                <FormControl>
                  <Input
                    type="number"
                    min={0}
                    step={1000}
                    inputMode="numeric"
                    value={field.value}
                    onChange={(event) =>
                      field.onChange(
                        event.target.value === '' ? 0 : Number(event.target.value),
                      )
                    }
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="stock"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Stok saat ini</FormLabel>
                <FormControl>
                  <Input
                    type="number"
                    min={0}
                    step={1}
                    inputMode="numeric"
                    value={field.value}
                    onChange={(event) =>
                      field.onChange(
                        event.target.value === ''
                          ? 0
                          : Math.floor(Number(event.target.value)),
                      )
                    }
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="minStock"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Stok minimum</FormLabel>
                <FormControl>
                  <Input
                    type="number"
                    min={0}
                    step={1}
                    inputMode="numeric"
                    value={field.value}
                    onChange={(event) =>
                      field.onChange(
                        event.target.value === ''
                          ? 0
                          : Math.floor(Number(event.target.value)),
                      )
                    }
                  />
                </FormControl>
                <FormDescription>
                  Peringatan muncul saat stok menyentuh angka ini.
                </FormDescription>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="unit"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Satuan</FormLabel>
                <FormControl>
                  <Input placeholder="pcs / cup / glass" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="imageUrl"
            render={({ field }) => (
              <FormItem className="sm:col-span-2">
                <FormLabel>URL gambar</FormLabel>
                <FormControl>
                  <Input placeholder="https://…" {...field} />
                </FormControl>
                <FormDescription>
                  Opsional. Biarkan kosong untuk memakai ikon produk.
                </FormDescription>
                <FormMessage />
              </FormItem>
            )}
          />
        </div>

        <DialogFooter>
          <Button type="button" variant="outline" onClick={onCancel}>
            Batal
          </Button>
          <Button type="submit" disabled={categories.length === 0}>
            {product ? 'Simpan perubahan' : 'Tambah produk'}
          </Button>
        </DialogFooter>
      </form>
    </Form>
  )
}
