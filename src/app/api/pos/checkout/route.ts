import crypto from "crypto";
import { and, eq, inArray, sql } from "drizzle-orm";
import { NextResponse } from "next/server";
import { z } from "zod";

import { getSession } from "@/lib/auth";
import { db } from "@/server/db";
import {
  businessSettings,
  checkoutIdempotency,
  customers,
  DEFAULT_BUSINESS_ID,
  DEFAULT_STORE_ID,
  inventory,
  payments,
  products,
  stockMovements,
  taxRates,
  transactionDiscounts,
  transactionItems,
  transactions,
} from "@/server/db/schema";

const CheckoutSchema = z.object({
  idempotencyKey: z.string().min(1),
  items: z
    .array(
      z.object({
        productId: z.string().min(1),
        quantity: z.number().int().positive(),
      })
    )
    .min(1),
  paymentMethod: z.enum(["cash", "card", "qris"]),
  paymentAmount: z.number().positive().optional(),
  customerId: z.string().optional(),
  customerName: z.string().optional(),
  orderType: z.enum(["dine-in", "takeaway"]).default("dine-in"),
  tableNumber: z.string().optional(),
  discount: z.number().min(0).default(0),
  // Diterima untuk kompatibilitas klien lama; nilai final dihitung server.
  tax: z.number().min(0).optional(),
  cashier: z.string().optional(),
});

function hashRequest(body: unknown) {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(body))
    .digest("hex");
}

function roundMoney(value: number) {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function generateTransactionNumber() {
  const date = new Date();
  const y = date.getFullYear().toString().slice(-2);
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  const rand = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `TRX-${y}${m}${d}-${rand}`;
}

export async function POST(request: Request) {
  try {
    const session = await getSession();
    const user =
      (session as any)?.user ?? (session as any)?.data?.user ?? null;

    if (!user) {
      return NextResponse.json(
        { error: "Checkout hanya tersedia untuk akun terdaftar." },
        { status: 401 }
      );
    }

    const body = await request.json();
    const parsed = CheckoutSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Data checkout tidak valid.", details: parsed.error.flatten() },
        { status: 400 }
      );
    }

    const payload = parsed.data;
    // Urutkan item agar urutan keranjang tidak mengubah idempotency hash.
    const canonicalItems = [...payload.items].sort((a, b) =>
      a.productId.localeCompare(b.productId)
    );
    const requestHash = hashRequest({
      items: canonicalItems,
      paymentMethod: payload.paymentMethod,
      paymentAmount: payload.paymentAmount,
      customerId: payload.customerId,
      customerName: payload.customerName,
      orderType: payload.orderType,
      tableNumber: payload.tableNumber,
      discount: payload.discount,
    });

    const result = await db.transaction(async (tx) => {
      // Serialisasi request dengan idempotency key yang sama.
      await tx.execute(
        sql`select pg_advisory_xact_lock(hashtext(${payload.idempotencyKey}))`
      );

      const existing = await tx
        .select()
        .from(checkoutIdempotency)
        .where(eq(checkoutIdempotency.key, payload.idempotencyKey))
        .limit(1);

      if (existing.length > 0) {
        if (existing[0].requestHash !== requestHash) {
          const conflict: any = new Error(
            "Idempotency key dipakai dengan payload berbeda."
          );
          conflict.status = 409;
          throw conflict;
        }
        if (existing[0].response) {
          return { cached: JSON.parse(existing[0].response) as unknown };
        }
      }

      const productIds = [...new Set(canonicalItems.map((item) => item.productId))].sort();
      const productRows = await tx
        .select()
        .from(products)
        .where(inArray(products.id, productIds))
        .orderBy(products.id)
        .for("update");

      const inventoryRows = await tx
        .select()
        .from(inventory)
        .where(
          and(
            eq(inventory.storeId, DEFAULT_STORE_ID),
            inArray(inventory.productId, productIds)
          )
        )
        .orderBy(inventory.productId)
        .for("update");

      const productById = new Map(productRows.map((row) => [row.id, row]));
      const inventoryByProduct = new Map(
        inventoryRows.map((row) => [row.productId, row])
      );

      const [settings] = await tx
        .select()
        .from(businessSettings)
        .where(eq(businessSettings.id, "default"))
        .limit(1);
      const [defaultTaxRate] = await tx
        .select()
        .from(taxRates)
        .where(
          and(
            eq(taxRates.businessId, DEFAULT_BUSINESS_ID),
            eq(taxRates.isDefault, true)
          )
        )
        .limit(1);
      const taxRate = settings
        ? Number(settings.taxRate)
        : Number(defaultTaxRate?.rate ?? 0);
      const [customer] = payload.customerId
        ? await tx
            .select({ id: customers.id })
            .from(customers)
            .where(
              and(
                eq(customers.id, payload.customerId),
                eq(customers.businessId, DEFAULT_BUSINESS_ID)
              )
            )
            .limit(1)
        : [];
      const memberDiscountRate = Number(settings?.memberDiscountRate ?? 0);

      const items: {
        productId: string;
        name: string;
        sku: string;
        quantity: number;
        unitPrice: number;
        lineTotal: number;
      }[] = [];
      let subtotal = 0;

      for (const item of canonicalItems) {
        const product = productById.get(item.productId);
        if (!product) {
          throw new Error(`Produk ${item.productId} tidak ditemukan.`);
        }
        if (product.status !== "active") {
          throw new Error(`Produk ${product.name} sedang tidak tersedia.`);
        }

        const inventoryRow = inventoryByProduct.get(item.productId);
        const available =
          inventoryRow?.stockQuantity ?? product.stockQuantity;
        if (available < item.quantity) {
          throw new Error(`Stok ${product.name} tidak cukup.`);
        }

        const unitPrice = Number(product.sellingPrice);
        const lineTotal = roundMoney(unitPrice * item.quantity);
        subtotal += lineTotal;
        items.push({
          productId: product.id,
          name: product.name,
          sku: product.sku,
          quantity: item.quantity,
          unitPrice,
          lineTotal,
        });
      }

      subtotal = roundMoney(subtotal);
      const eligibleDiscount = customer
        ? roundMoney(subtotal * memberDiscountRate)
        : 0;
      const discount = roundMoney(
        Math.min(payload.discount, subtotal, eligibleDiscount)
      );
      const taxableSubtotal = roundMoney(subtotal - discount);
      const tax = roundMoney(taxableSubtotal * taxRate);
      const total = roundMoney(taxableSubtotal + tax);
      const paid =
        payload.paymentMethod === "cash"
          ? roundMoney(payload.paymentAmount ?? total)
          : total;

      if (payload.paymentMethod === "cash" && paid < total) {
        throw new Error("Nominal pembayaran kurang.");
      }

      const change = roundMoney(Math.max(0, paid - total));
      const transactionId = crypto.randomUUID();
      const transactionNumber = generateTransactionNumber();
      const createdAt = new Date();
      const cashierName = payload.cashier || user.name || "Kasir";

      const [transaction] = await tx
        .insert(transactions)
        .values({
          id: transactionId,
          businessId: DEFAULT_BUSINESS_ID,
          storeId: DEFAULT_STORE_ID,
          transactionNumber,
          cashierId: user.id,
          cashierName,
          customerId: payload.customerId ?? null,
          customerName: payload.customerName ?? "Umum",
          orderType: payload.orderType,
          tableNumber: payload.tableNumber ?? null,
          paymentMethod: payload.paymentMethod,
          paymentStatus: "paid",
          taxRateId: defaultTaxRate?.id ?? null,
          subtotal: subtotal.toFixed(2),
          discountTotal: discount.toFixed(2),
          taxTotal: tax.toFixed(2),
          grandTotal: total.toFixed(2),
          amountPaid: paid.toFixed(2),
          changeAmount: change.toFixed(2),
          status: "completed",
          createdAt,
          updatedAt: createdAt,
        })
        .returning();

      for (const item of items) {
        const product = productById.get(item.productId)!;
        const inventoryRow = inventoryByProduct.get(item.productId);
        const available =
          inventoryRow?.stockQuantity ?? product.stockQuantity;
        const nextStock = available - item.quantity;

        await tx.insert(transactionItems).values({
          id: crypto.randomUUID(),
          transactionId,
          productId: item.productId,
          productName: item.name,
          sku: item.sku,
          quantity: item.quantity,
          unitPrice: item.unitPrice.toFixed(2),
          lineTotal: item.lineTotal.toFixed(2),
          costPrice: product.costPrice,
          createdAt,
        });

        await tx
          .update(products)
          .set({
            stockQuantity: sql`${products.stockQuantity} - ${item.quantity}`,
            updatedAt: new Date(),
          })
          .where(eq(products.id, item.productId));

        await tx
          .insert(inventory)
          .values({
            businessId: DEFAULT_BUSINESS_ID,
            storeId: DEFAULT_STORE_ID,
            productId: item.productId,
            stockQuantity: nextStock,
            minimumStock:
              inventoryRow?.minimumStock ?? product.minimumStock,
            updatedAt: new Date(),
          })
          .onConflictDoUpdate({
            target: [inventory.productId, inventory.storeId],
            set: {
              stockQuantity: nextStock,
              updatedAt: new Date(),
            },
          });

        await tx.insert(stockMovements).values({
          id: crypto.randomUUID(),
          businessId: DEFAULT_BUSINESS_ID,
          storeId: DEFAULT_STORE_ID,
          productId: item.productId,
          productName: item.name,
          movementType: "sale",
          quantity: -item.quantity,
          stockAfter: nextStock,
          unitCost: product.costPrice,
          note: `Penjualan ${transactionNumber}`,
          staffName: cashierName,
          referenceType: "transaction",
          referenceId: transactionId,
          createdAt,
        });
      }

      await tx.insert(payments).values({
        transactionId,
        paymentMethod: payload.paymentMethod,
        amount: paid.toFixed(2),
        status: "completed",
        paidAt: createdAt,
      });

      if (discount > 0) {
        await tx.insert(transactionDiscounts).values({
          transactionId,
          name: "Diskon manual",
          type: "fixed",
          value: discount.toFixed(2),
          amount: discount.toFixed(2),
          createdAt,
        });
      }

      const response = {
        transaction: {
          id: transaction.id,
          number: transaction.transactionNumber,
          createdAt: transaction.createdAt.toISOString(),
          cashier: cashierName,
          customerId: payload.customerId,
          customerName: payload.customerName ?? "Umum",
          orderType: payload.orderType,
          tableNumber: payload.tableNumber,
          items,
          subtotal,
          discount,
          tax,
          total,
          paymentMethod: payload.paymentMethod,
          cashReceived: paid,
          change,
          status: "completed",
        },
        transactionId: transaction.id,
        transactionNumber: transaction.transactionNumber,
        subtotal,
        discount,
        tax,
        total,
        paymentMethod: transaction.paymentMethod,
        amountPaid: paid,
        changeAmount: change,
        items,
        status: transaction.status,
        createdAt: transaction.createdAt.toISOString(),
      };

      await tx
        .insert(checkoutIdempotency)
        .values({
          key: payload.idempotencyKey,
          requestHash,
          transactionId,
          response: JSON.stringify(response),
          createdAt,
          expiresAt: new Date(Date.now() + 86400000),
        })
        .onConflictDoUpdate({
          target: checkoutIdempotency.key,
          set: {
            transactionId,
            response: JSON.stringify(response),
          },
        });

      return { response };
    });

    if ("cached" in result) {
      return NextResponse.json(result.cached);
    }

    return NextResponse.json(result.response);
  } catch (error: any) {
    console.error("Checkout error:", error?.message ?? error);
    return NextResponse.json(
      { error: error?.message || "Checkout gagal." },
      { status: error?.status ?? 400 }
    );
  }
}
