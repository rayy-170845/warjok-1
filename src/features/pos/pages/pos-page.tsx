"use client";

import { useEffect, useMemo, useRef, useState } from 'react'
import { ShoppingCartIcon } from 'lucide-react'
import { toast } from 'sonner'

import { Button } from '@/components/ui/button'
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetTitle,
} from '@/components/ui/sheet'
import { useBusinessStore } from '@/stores/business-store'
import { useRealUser } from '@/hooks/use-real-user'
import { formatCurrency } from '@/lib/format'
import { CartPanel } from '../components/cart-panel'
import { CheckoutDialog } from '../components/checkout-dialog'
import { CustomerPickerDialog } from '../components/customer-picker-dialog'
import { ProductCatalog } from '../components/product-catalog'
import { PosToolbar } from '../components/pos-toolbar'
import { usePosCart } from '../hooks/use-pos-cart'
import { computeTotals } from '../lib/pricing'
import { createOrderId } from '../lib/order'
import type { PosOrderType } from '../lib/order'

export default function PosPage() {
  const products = useBusinessStore((state) => state.products)
  const categories = useBusinessStore((state) => state.categories)
  const customers = useBusinessStore((state) => state.customers)
  const settings = useBusinessStore((state) => state.settings)
  const transactions = useBusinessStore((state) => state.transactions)
  const completeSale = useBusinessStore((state) => state.completeSale)
  const recordServerSale = useBusinessStore((state) => state.recordServerSale)
  const realUser = useRealUser(true)
  const cart = usePosCart(products)
  const [search, setSearch] = useState('')
  const [categoryId, setCategoryId] = useState('all')
  const [orderType, setOrderType] = useState<PosOrderType>('dine-in')
  const [tableNumber, setTableNumber] = useState('')
  const [customerId, setCustomerId] = useState<string | null>(null)
  const [customerName, setCustomerName] = useState('')
  const [memberApplied, setMemberApplied] = useState(true)
  const [cartOpen, setCartOpen] = useState(false)
  const [checkoutOpen, setCheckoutOpen] = useState(false)
  const [customerPickerOpen, setCustomerPickerOpen] = useState(false)
  const [orderId, setOrderId] = useState(() => createOrderId())
  const searchRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    const handler = (event: KeyboardEvent) => {
      if (event.key === 'F2') {
        event.preventDefault()
        setCartOpen(false)
        setCheckoutOpen((open) => !open)
      }
      if (event.key === 'F9') {
        event.preventDefault()
        cart.clear()
        setCartOpen(false)
        toast.success('Keranjang dikosongkan')
      }
      if (event.key === '/') {
        const target = event.target as HTMLElement | null
        if (target && ['INPUT', 'TEXTAREA'].includes(target.tagName)) return
        if (target?.isContentEditable) return
        event.preventDefault()
        searchRef.current?.focus()
      }
      if (event.key === 'Escape') {
        setCartOpen(false)
        setCheckoutOpen(false)
        setCustomerPickerOpen(false)
      }
    }

    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [cart])

  const posProducts = useMemo(
    () =>
      products
        .filter((product) => product.status === 'active')
        .map((product) => ({
          id: product.id,
          name: product.name,
          sku: product.sku,
          categoryId: product.categoryId,
          price: product.price,
          stock: product.stock,
          imageUrl: product.imageUrl,
        })),
    [products],
  )

  const posCategories = useMemo(
    () => [
      { id: 'all', label: 'Semua', icon: null, count: posProducts.length },
      ...categories.filter((cat) => cat.status === 'active').map((cat) => ({
        id: cat.id,
        label: cat.name,
        icon: null,
        count: posProducts.filter((p) => p.categoryId === cat.id).length,
      })),
    ],
    [categories, posProducts],
  )

  const customerMap = useMemo(() => {
    const map = new Map<string, string>()
    for (const customer of customers) {
      map.set(customer.id, customer.name)
    }
    return map
  }, [customers])

  const selectedCustomer = customerId
    ? customers.find((customer) => customer.id === customerId)
    : undefined
  const memberEligible = Boolean(selectedCustomer)
  const effectiveMember = memberEligible && memberApplied

  const totals = useMemo(
    () =>
      computeTotals(cart.subtotal, effectiveMember, {
        memberDiscountRate: settings.memberDiscountRate,
        taxRate: settings.taxRate,
      }),
    [cart.subtotal, effectiveMember, settings.memberDiscountRate, settings.taxRate],
  )

  const quantityByProductId = useMemo(() => {
    const map: Record<string, number> = {}
    for (const line of cart.lines) {
      map[line.product.id] = line.quantity
    }
    return map
  }, [cart.lines])

  const filteredProducts = useMemo(() => {
    const query = search.trim().toLowerCase()

    return posProducts.filter((product) => {
      const matchesCategory =
        categoryId === 'all' || product.categoryId === categoryId
      const matchesQuery =
        query.length === 0 ||
        product.name.toLowerCase().includes(query) ||
        (product.sku ?? '').toLowerCase().includes(query)

      return matchesCategory && matchesQuery
    })
  }, [posProducts, search, categoryId])

  const handleSelectCustomer = (nextCustomerId: string | null) => {
    setCustomerId(nextCustomerId)
    setCustomerName(
      nextCustomerId ? customerMap.get(nextCustomerId) ?? '' : '',
    )
    setMemberApplied(true)
  }

  const handleComplete = (sale: any, serverResult?: any) => {
    setCartOpen(false)

    if (serverResult?.transaction) {
      recordServerSale(serverResult.transaction)
      cart.clear()
      setOrderId(createOrderId())
      setTableNumber('')
      setCustomerId(null)
      setCustomerName('')
      setMemberApplied(true)
      return serverResult.transactionNumber as string
    }

    const transaction = completeSale(sale)
    cart.clear()
    setOrderId(createOrderId())
    setTableNumber('')
    setCustomerId(null)
    setCustomerName('')
    setMemberApplied(true)
    return transaction.number
  }

  return (
    <div className="flex h-[calc(100svh-4rem)] flex-col overflow-hidden md:h-[calc(100svh-5rem)]">
      <section className="flex min-h-0 min-w-0 flex-1 flex-col gap-2">
        <PosToolbar
          search={search}
          onSearchChange={setSearch}
          inputRef={searchRef}
          onOpenDrawer={() =>
            toast('Laci kasir dibuka', {
              description: 'Simulasi perangkat — belum tersambung.',
            })
          }
        />
        <ProductCatalog
          products={filteredProducts}
          categories={posCategories as any}
          activeCategory={categoryId}
          quantities={quantityByProductId}
          onCategoryChange={setCategoryId}
          onAdd={cart.add}
        />
      </section>

      {cart.itemCount > 0 ? (
        <Button
          type="button"
          onClick={() => setCartOpen(true)}
          className="fixed right-4 bottom-4 z-40 h-12 animate-in gap-2 rounded-full px-4 shadow-lg shadow-primary/20 transition-transform duration-200 fade-in hover:scale-[1.02] active:scale-[0.98] md:right-6 md:bottom-6"
          aria-label={`Buka pesanan saat ini, ${cart.itemCount} item, total ${formatCurrency(totals.total)}`}
          aria-haspopup="dialog"
          aria-expanded={cartOpen}
        >
          <span className="relative">
            <ShoppingCartIcon className="size-5" />
            <span className="absolute -top-1.5 -right-1.5 flex h-5 min-w-5 items-center justify-center rounded-full bg-background px-1 text-[10px] font-bold text-primary ring-2 ring-primary">
              {cart.itemCount}
            </span>
          </span>
          <span className="flex flex-col items-start leading-none">
            <span className="text-[10px] font-medium tracking-wide uppercase opacity-80">
              Pesanan
            </span>
            <span className="text-sm font-semibold tabular-nums">
              {formatCurrency(totals.total)}
            </span>
          </span>
        </Button>
      ) : null}

      <Sheet open={cartOpen} onOpenChange={setCartOpen}>
        <SheetContent
          side="right"
          showCloseButton={false}
          className="gap-0 p-0 data-[side=right]:w-full data-[side=right]:sm:max-w-md"
        >
          <SheetTitle className="sr-only">Pesanan Saat Ini</SheetTitle>
          <SheetDescription className="sr-only">
            Detail keranjang, pelanggan, tipe pesanan, dan total pesanan.
          </SheetDescription>
          <CartPanel
            orderId={orderId}
            lines={cart.lines}
            itemCount={cart.itemCount}
            totals={totals}
            member={effectiveMember}
            memberEligible={memberEligible}
            memberDiscountRate={settings.memberDiscountRate}
            taxRate={settings.taxRate}
            onToggleMember={() => setMemberApplied((value) => !value)}
            customerName={customerName}
            onCustomerNameChange={setCustomerName}
            onOpenCustomerPicker={() => setCustomerPickerOpen(true)}
            orderType={orderType}
            onOrderTypeChange={setOrderType}
            tableNumber={tableNumber}
            onTableNumberChange={setTableNumber}
            onIncrement={cart.increment}
            onDecrement={cart.decrement}
            onRemove={cart.remove}
            onClear={cart.clear}
            onCheckout={() => {
              setCartOpen(false)
              setCheckoutOpen(true)
            }}
            onClose={() => setCartOpen(false)}
            className="h-full rounded-none border-0"
          />
        </SheetContent>
      </Sheet>
      <CheckoutDialog
        open={checkoutOpen}
        onOpenChange={setCheckoutOpen}
        orderId={orderId}
        lines={cart.lines}
        itemCount={cart.itemCount}
        totals={totals}
        orderType={orderType}
        tableNumber={tableNumber}
        customerId={customerId ?? undefined}
        customerName={customerName || 'Pelanggan umum'}
        cashierName={realUser?.name ?? 'Kasir'}
        settings={settings}
        onTableNumberChange={setTableNumber}
        onComplete={handleComplete}
      />
      <CustomerPickerDialog
        open={customerPickerOpen}
        onOpenChange={setCustomerPickerOpen}
        customers={customers}
        transactions={transactions}
        memberDiscountRate={settings.memberDiscountRate}
        selectedId={customerId}
        onSelect={handleSelectCustomer}
      />
    </div>
  )
}
