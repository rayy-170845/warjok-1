import { and, desc, eq, gte, ilike, inArray, lte, or } from "drizzle-orm";

import { BUSINESS_SETTINGS } from "@/lib/business-seed";
import type {
  BusinessSettings,
  Category,
  Customer,
  EntityStatus,
  Product,
  Staff,
  StockMovement,
  Transaction,
  TransactionItem,
} from "@/types/business";
import { db } from "@/server/db";
import {
  businesses,
  businessSettings,
  categories,
  customers,
  DEFAULT_BUSINESS_ID,
  DEFAULT_STORE_ID,
  inventory,
  products,
  receiptSettings,
  staff,
  stores,
  stockAdjustments,
  stockMovements,
  transactionItems,
  transactions,
} from "@/server/db/schema";

const money = (value: number) => value.toFixed(2);
const number = (value: string | null | undefined) => Number(value ?? 0);
const iso = (value: Date | string) => new Date(value).toISOString();

export type BusinessData = {
  setupRequired: boolean;
  categories: Category[];
  products: Product[];
  customers: Customer[];
  staff: Staff[];
  transactions: Transaction[];
  movements: StockMovement[];
  settings: BusinessSettings;
};

export type BusinessQuery = {
  page?: number;
  pageSize?: number;
  search?: string;
  categoryId?: string;
  status?: string;
  stockFilter?: string;
  payment?: string;
  from?: string;
  to?: string;
};

export type ActingUser = {
  actingUserId?: string;
  actingUserRole?: string;
};

/**
 * Upsert stok toko default. Tabel `Inventory` adalah sumber kebenaran per
 * toko; `Products.StockQuantity` tetap diperbarui sebagai cache kompatibilitas
 * untuk alur POS lama.
 */
async function upsertInventory(
  tx: any,
  productId: string,
  stockQuantity: number,
  minimumStock: number
) {
  await tx
    .insert(inventory)
    .values({
      businessId: DEFAULT_BUSINESS_ID,
      storeId: DEFAULT_STORE_ID,
      productId,
      stockQuantity,
      minimumStock,
      updatedAt: new Date(),
    })
    .onConflictDoUpdate({
      target: [inventory.productId, inventory.storeId],
      set: {
        stockQuantity,
        minimumStock,
        updatedAt: new Date(),
      },
    });
}

export async function getBusinessData(query: BusinessQuery = {}): Promise<BusinessData> {
  const {
    page = 1,
    pageSize = 20,
    search,
    categoryId,
    status,
    stockFilter: _stockFilter,
    payment,
    from,
    to,
  } = query;

  const offset = (page - 1) * pageSize;

  const transactionFilters: any[] = [
    eq(transactions.businessId, DEFAULT_BUSINESS_ID),
  ];
  if (search) {
    transactionFilters.push(
      or(
        ilike(transactions.transactionNumber, `%${search}%`),
        ilike(transactions.customerName, `%${search}%`),
        ilike(transactions.cashierName, `%${search}%`)
      )
    );
  }
  if (status) transactionFilters.push(eq(transactions.status, status));
  if (payment) transactionFilters.push(eq(transactions.paymentMethod, payment));
  if (from) transactionFilters.push(gte(transactions.createdAt, new Date(from)));
  if (to) transactionFilters.push(lte(transactions.createdAt, new Date(to)));

  const productFilters: any[] = [
    eq(products.businessId, DEFAULT_BUSINESS_ID),
  ];
  if (search) {
    productFilters.push(
      or(
        ilike(products.name, `%${search}%`),
        ilike(products.sku, `%${search}%`),
        ilike(products.barcode ?? "", `%${search}%`)
      )
    );
  }
  if (categoryId) productFilters.push(eq(products.categoryId, categoryId));
  if (status) productFilters.push(eq(products.status, status));

  const customerFilters: any[] = [
    eq(customers.businessId, DEFAULT_BUSINESS_ID),
  ];
  if (search) {
    customerFilters.push(
      or(
        ilike(customers.name, `%${search}%`),
        ilike(customers.phone, `%${search}%`),
        ilike(customers.email, `%${search}%`)
      )
    );
  }

  const staffFilters: any[] = [eq(staff.businessId, DEFAULT_BUSINESS_ID)];
  if (search) {
    staffFilters.push(
      or(
        ilike(staff.name, `%${search}%`),
        ilike(staff.email, `%${search}%`)
      )
    );
  }
  if (status) staffFilters.push(eq(staff.status, status));

  const [
    businessRows,
    storeRows,
    categoryRows,
    productRows,
    customerRows,
    staffRows,
    settingsRows,
    receiptRows,
    transactionRows,
    itemRows,
    movementRows,
  ] = await Promise.all([
    db
      .select({ id: businesses.id })
      .from(businesses)
      .where(eq(businesses.id, DEFAULT_BUSINESS_ID))
      .limit(1),
    db
      .select({ id: stores.id })
      .from(stores)
      .where(eq(stores.id, DEFAULT_STORE_ID))
      .limit(1),
    db
      .select()
      .from(categories)
      .where(eq(categories.businessId, DEFAULT_BUSINESS_ID)),
    db
      .select()
      .from(products)
      .where(and(...productFilters))
      .limit(pageSize)
      .offset(offset),
    db
      .select()
      .from(customers)
      .where(and(...customerFilters))
      .limit(pageSize)
      .offset(offset),
    db
      .select()
      .from(staff)
      .where(and(...staffFilters))
      .limit(pageSize)
      .offset(offset),
    db
      .select()
      .from(businessSettings)
      .where(eq(businessSettings.id, "default")),
    db
      .select()
      .from(receiptSettings)
      .where(
        and(
          eq(receiptSettings.businessId, DEFAULT_BUSINESS_ID),
          eq(receiptSettings.storeId, DEFAULT_STORE_ID)
        )
      ),
    db
      .select()
      .from(transactions)
      .where(and(...transactionFilters))
      .orderBy(desc(transactions.createdAt))
      .limit(pageSize)
      .offset(offset),
    db.select().from(transactionItems),
    db
      .select()
      .from(stockMovements)
      .where(eq(stockMovements.businessId, DEFAULT_BUSINESS_ID)),
  ]);

  const productIds = productRows.map((row) => row.id);
  const inventoryRows =
    productIds.length > 0
      ? await db
          .select()
          .from(inventory)
          .where(
            and(
              eq(inventory.storeId, DEFAULT_STORE_ID),
              inArray(inventory.productId, productIds)
            )
          )
      : [];
  const inventoryByProduct = new Map(
    inventoryRows.map((row) => [row.productId, row])
  );

  const itemsByTransaction = new Map<string, TransactionItem[]>();
  for (const item of itemRows) {
    const list = itemsByTransaction.get(item.transactionId) ?? [];
    list.push({
      productId: item.productId,
      name: item.productName,
      sku: item.sku ?? "",
      quantity: item.quantity,
      unitPrice: number(item.unitPrice),
      lineTotal: number(item.lineTotal),
    });
    itemsByTransaction.set(item.transactionId, list);
  }

  const mappedTransactions: Transaction[] = transactionRows
    .map((row) => ({
      id: row.id,
      number: row.transactionNumber,
      createdAt: iso(row.createdAt),
      cashier: row.cashierName ?? "Kasir",
      customerId: row.customerId ?? undefined,
      customerName: row.customerName ?? "Umum",
      orderType:
        row.orderType === "takeaway"
          ? ("takeaway" as const)
          : ("dine-in" as const),
      tableNumber: row.tableNumber ?? undefined,
      items: itemsByTransaction.get(row.id) ?? [],
      subtotal: number(row.subtotal),
      discount: number(row.discountTotal),
      tax: number(row.taxTotal),
      total: number(row.grandTotal),
      paymentMethod: row.paymentMethod as Transaction["paymentMethod"],
      cashReceived: row.amountPaid ? number(row.amountPaid) : undefined,
      change: row.changeAmount ? number(row.changeAmount) : undefined,
      status: row.status as Transaction["status"],
      voidReason: row.voidReason ?? undefined,
    }))
    .sort(
      (a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );

  const settingsRow = settingsRows[0];
  const receiptRow = receiptRows[0];
  const mappedSettings: BusinessSettings = settingsRow
    ? {
        businessName: settingsRow.businessName,
        address: settingsRow.address,
        phone: settingsRow.phone,
        email: settingsRow.email,
        currency: settingsRow.currency,
        timezone: settingsRow.timezone,
        taxRate: number(settingsRow.taxRate),
        memberDiscountRate: number(settingsRow.memberDiscountRate),
        lowStockThreshold: settingsRow.lowStockThreshold,
        receiptFooter:
          receiptRow?.footer ?? settingsRow.legacyReceiptFooter ?? "",
      }
    : BUSINESS_SETTINGS;

  return {
    setupRequired: businessRows.length === 0 || storeRows.length === 0,
    categories: categoryRows
      .map((row) => ({
        id: row.id,
        name: row.name,
        description: row.description ?? undefined,
        status: row.status as EntityStatus,
        createdAt: iso(row.createdAt),
      }))
      .sort((a, b) => a.name.localeCompare(b.name)),
    products: productRows
      .map((row) => {
        const stockRow = inventoryByProduct.get(row.id);
        return {
          id: row.id,
          name: row.name,
          sku: row.sku,
          barcode: row.barcode ?? undefined,
          categoryId: row.categoryId ?? "",
          price: number(row.sellingPrice),
          cost: number(row.costPrice),
          stock: stockRow?.stockQuantity ?? row.stockQuantity,
          minStock: stockRow?.minimumStock ?? row.minimumStock,
          unit: row.unit,
          imageUrl: row.imageUrl ?? undefined,
          status: row.status as EntityStatus,
          createdAt: iso(row.createdAt),
        };
      })
      .sort((a, b) => a.name.localeCompare(b.name)),
    customers: customerRows
      .map((row) => ({
        id: row.id,
        name: row.name,
        phone: row.phone,
        email: row.email ?? undefined,
        notes: row.notes ?? undefined,
        joinedAt: iso(row.joinedAt),
      }))
      .sort(
        (a, b) =>
          new Date(b.joinedAt).getTime() - new Date(a.joinedAt).getTime()
      ),
    staff: staffRows
      .map((row) => ({
        id: row.id,
        name: row.name,
        email: row.email,
        role: row.role as Staff["role"],
        status: row.status as Staff["status"],
        joinedAt: iso(row.joinedAt),
        lastActive: row.lastActive ? iso(row.lastActive) : undefined,
      }))
      .sort((a, b) => a.name.localeCompare(b.name)),
    transactions: mappedTransactions,
    movements: movementRows
      .map((row) => ({
        id: row.id,
        productId: row.productId ?? "",
        productName: row.productName,
        type: row.movementType as StockMovement["type"],
        quantity: row.quantity,
        stockAfter: row.stockAfter,
        note: row.note ?? "",
        staff: row.staffName ?? "Kasir",
        createdAt: iso(row.createdAt),
      }))
      .sort(
        (a, b) =>
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      ),
    settings: mappedSettings,
  };
}

function requiredId(value: unknown, label: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error(`${label} tidak valid.`);
  }
  return value;
}

export async function mutateBusiness(
  action: string,
  payload: any,
  actingUser: ActingUser = {}
) {
  const { actingUserId, actingUserRole: _actingUserRole } = actingUser;
  switch (action) {
    case "category.create": {
      await db.insert(categories).values({
        id: requiredId(payload.id, "ID kategori"),
        businessId: DEFAULT_BUSINESS_ID,
        name: String(payload.name ?? "").trim(),
        description: payload.description?.trim() || null,
        status: payload.status ?? "active",
        createdAt: payload.createdAt ? new Date(payload.createdAt) : new Date(),
        updatedAt: new Date(),
      });
      return { ok: true };
    }

    case "category.update": {
      await db
        .update(categories)
        .set({
          name: String(payload.name ?? "").trim(),
          description: payload.description?.trim() || null,
          status: payload.status ?? "active",
          updatedAt: new Date(),
        })
        .where(eq(categories.id, requiredId(payload.id, "ID kategori")));
      return { ok: true };
    }

    case "category.delete": {
      const id = requiredId(payload.id, "ID kategori");
      const used = await db
        .select({ id: products.id })
        .from(products)
        .where(eq(products.categoryId, id))
        .limit(1);
      if (used.length > 0) {
        throw new Error("Kategori masih dipakai produk. Pindahkan produk dulu.");
      }
      await db.delete(categories).where(eq(categories.id, id));
      return { ok: true };
    }

    case "product.create": {
      const id = requiredId(payload.id, "ID produk");
      const stock = Number(payload.stock ?? 0);
      const minStock = Number(payload.minStock ?? 0);

      await db.transaction(async (tx) => {
        await tx.insert(products).values({
          id,
          businessId: DEFAULT_BUSINESS_ID,
          name: String(payload.name ?? "").trim(),
          sku: String(payload.sku ?? "").trim().toUpperCase(),
          barcode: payload.barcode?.trim() || null,
          categoryId: payload.categoryId || null,
          sellingPrice: money(Number(payload.price ?? 0)),
          costPrice: money(Number(payload.cost ?? 0)),
          stockQuantity: stock,
          minimumStock: minStock,
          unit: String(payload.unit ?? "pcs").trim() || "pcs",
          imageUrl: payload.imageUrl?.trim() || null,
          status: payload.status ?? "active",
          createdAt: payload.createdAt ? new Date(payload.createdAt) : new Date(),
          updatedAt: new Date(),
        });
        await upsertInventory(tx, id, stock, minStock);
      });
      return { ok: true };
    }

    case "product.update": {
      const id = requiredId(payload.id, "ID produk");
      const stock = Number(payload.stock ?? 0);
      const minStock = Number(payload.minStock ?? 0);

      await db.transaction(async (tx) => {
        await tx
          .update(products)
          .set({
            name: String(payload.name ?? "").trim(),
            sku: String(payload.sku ?? "").trim().toUpperCase(),
            barcode: payload.barcode?.trim() || null,
            categoryId: payload.categoryId || null,
            sellingPrice: money(Number(payload.price ?? 0)),
            costPrice: money(Number(payload.cost ?? 0)),
            stockQuantity: stock,
            minimumStock: minStock,
            unit: String(payload.unit ?? "pcs").trim() || "pcs",
            imageUrl: payload.imageUrl?.trim() || null,
            status: payload.status ?? "active",
            updatedAt: new Date(),
          })
          .where(eq(products.id, id));
        await upsertInventory(tx, id, stock, minStock);
      });
      return { ok: true };
    }

    case "product.status": {
      await db
        .update(products)
        .set({ status: payload.status, updatedAt: new Date() })
        .where(eq(products.id, requiredId(payload.id, "ID produk")));
      return { ok: true };
    }

    case "product.delete": {
      const id = requiredId(payload.id, "ID produk");
      const [usedInTransaction, usedInMovement] = await Promise.all([
        db
          .select({ id: transactionItems.id })
          .from(transactionItems)
          .where(eq(transactionItems.productId, id))
          .limit(1),
        db
          .select({ id: stockMovements.id })
          .from(stockMovements)
          .where(eq(stockMovements.productId, id))
          .limit(1),
      ]);
      if (usedInTransaction.length > 0 || usedInMovement.length > 0) {
        throw new Error(
          "Produk sudah punya riwayat transaksi/stok. Arsipkan saja agar riwayat tetap utuh."
        );
      }
      await db.transaction(async (tx) => {
        await tx.delete(inventory).where(eq(inventory.productId, id));
        await tx.delete(products).where(eq(products.id, id));
      });
      return { ok: true };
    }

    case "customer.create": {
      await db.insert(customers).values({
        id: requiredId(payload.id, "ID pelanggan"),
        businessId: DEFAULT_BUSINESS_ID,
        name: String(payload.name ?? "").trim(),
        phone: String(payload.phone ?? "").trim(),
        email: payload.email?.trim() || null,
        notes: payload.notes?.trim() || null,
        joinedAt: payload.joinedAt ? new Date(payload.joinedAt) : new Date(),
        updatedAt: new Date(),
      });
      return { ok: true };
    }

    case "customer.update": {
      await db
        .update(customers)
        .set({
          name: String(payload.name ?? "").trim(),
          phone: String(payload.phone ?? "").trim(),
          email: payload.email?.trim() || null,
          notes: payload.notes?.trim() || null,
          updatedAt: new Date(),
        })
        .where(eq(customers.id, requiredId(payload.id, "ID pelanggan")));
      return { ok: true };
    }

    case "customer.delete": {
      await db
        .delete(customers)
        .where(eq(customers.id, requiredId(payload.id, "ID pelanggan")));
      return { ok: true };
    }

    case "staff.create": {
      await db.insert(staff).values({
        id: requiredId(payload.id, "ID staf"),
        businessId: DEFAULT_BUSINESS_ID,
        storeId: DEFAULT_STORE_ID,
        name: String(payload.name ?? "").trim(),
        email: String(payload.email ?? "").trim().toLowerCase(),
        role: payload.role ?? "cashier",
        status: payload.status ?? "active",
        joinedAt: payload.joinedAt ? new Date(payload.joinedAt) : new Date(),
        lastActive: new Date(),
        updatedAt: new Date(),
      });
      return { ok: true };
    }

    case "staff.update": {
      await db
        .update(staff)
        .set({
          name: String(payload.name ?? "").trim(),
          email: String(payload.email ?? "").trim().toLowerCase(),
          role: payload.role ?? "cashier",
          status: payload.status ?? "active",
          updatedAt: new Date(),
        })
        .where(eq(staff.id, requiredId(payload.id, "ID staf")));
      return { ok: true };
    }

    case "staff.delete": {
      const id = requiredId(payload.id, "ID staf");
      const [member] = await db
        .select()
        .from(staff)
        .where(eq(staff.id, id))
        .limit(1);
      if (member?.role === "owner") {
        throw new Error("Akun owner tidak bisa dihapus.");
      }
      await db.delete(staff).where(eq(staff.id, id));
      return { ok: true };
    }

    case "stock.adjust": {
      const productId = requiredId(payload.productId, "ID produk");
      const quantity = Number(payload.quantity ?? 0);
      if (!Number.isFinite(quantity) || quantity < 0) {
        throw new Error("Jumlah stok tidak valid.");
      }

      const mode = payload.mode as "in" | "out" | "adjustment";
      if (!["in", "out", "adjustment"].includes(mode)) {
        throw new Error("Mode penyesuaian stok tidak valid.");
      }

      await db.transaction(async (tx) => {
        const [product] = await tx
          .select()
          .from(products)
          .where(eq(products.id, productId))
          .for("update")
          .limit(1);
        if (!product) throw new Error("Produk tidak ditemukan.");

        const [inventoryRow] = await tx
          .select()
          .from(inventory)
          .where(
            and(
              eq(inventory.productId, productId),
              eq(inventory.storeId, DEFAULT_STORE_ID)
            )
          )
          .for("update")
          .limit(1);

        const currentStock = inventoryRow?.stockQuantity ?? product.stockQuantity;
        const delta =
          mode === "in"
            ? quantity
            : mode === "out"
              ? -quantity
              : quantity - currentStock;
        const nextStock = currentStock + delta;
        if (nextStock < 0) throw new Error("Stok tidak boleh negatif.");

        await tx
          .update(products)
          .set({ stockQuantity: nextStock, updatedAt: new Date() })
          .where(eq(products.id, productId));
        await upsertInventory(
          tx,
          productId,
          nextStock,
          inventoryRow?.minimumStock ?? product.minimumStock
        );

        const movementId = payload.movementId ?? crypto.randomUUID();
        await tx.insert(stockMovements).values({
          id: movementId,
          businessId: DEFAULT_BUSINESS_ID,
          storeId: DEFAULT_STORE_ID,
          productId,
          productName: product.name,
          movementType: mode,
          quantity: delta,
          stockAfter: nextStock,
          note: String(payload.note ?? "").trim() || "Penyesuaian stok",
          staffName: String(payload.staff ?? "").trim() || "Kasir",
          referenceType: "adjustment",
          referenceId: movementId,
          createdAt: new Date(),
        });

        await tx.insert(stockAdjustments).values({
          businessId: DEFAULT_BUSINESS_ID,
          storeId: DEFAULT_STORE_ID,
          productId,
          adjustmentType:
            mode === "in" ? "increase" : mode === "out" ? "decrease" : "set",
          quantity,
          reason: String(payload.note ?? "").trim() || "Penyesuaian stok",
          notes: String(payload.note ?? "").trim() || null,
          adjustedByUserId: actingUserId ?? null,
          createdAt: new Date(),
        });
      });

      return { ok: true };
    }

    case "transaction.void": {
      const id = requiredId(payload.id, "ID transaksi");

      await db.transaction(async (tx) => {
        const [transaction] = await tx
          .select()
          .from(transactions)
          .where(eq(transactions.id, id))
          .for("update")
          .limit(1);
        if (!transaction) throw new Error("Transaksi tidak ditemukan.");
        if (transaction.status !== "completed") {
          throw new Error("Hanya transaksi selesai yang bisa dibatalkan.");
        }

        const items = await tx
          .select()
          .from(transactionItems)
          .where(eq(transactionItems.transactionId, id));

        for (const item of items) {
          const [product] = await tx
            .select()
            .from(products)
            .where(eq(products.id, item.productId))
            .for("update")
            .limit(1);
          if (!product) continue;

          const [inventoryRow] = await tx
            .select()
            .from(inventory)
            .where(
              and(
                eq(inventory.productId, product.id),
                eq(inventory.storeId, DEFAULT_STORE_ID)
              )
            )
            .for("update")
            .limit(1);

          const currentStock =
            inventoryRow?.stockQuantity ?? product.stockQuantity;
          const nextStock = currentStock + item.quantity;

          await tx
            .update(products)
            .set({ stockQuantity: nextStock, updatedAt: new Date() })
            .where(eq(products.id, product.id));
          await upsertInventory(
            tx,
            product.id,
            nextStock,
            inventoryRow?.minimumStock ?? product.minimumStock
          );

          await tx.insert(stockMovements).values({
            id: crypto.randomUUID(),
            businessId: DEFAULT_BUSINESS_ID,
            storeId: DEFAULT_STORE_ID,
            productId: product.id,
            productName: product.name,
            movementType: "void",
            quantity: item.quantity,
            stockAfter: nextStock,
            note: `Pembatalan ${transaction.transactionNumber}`,
            staffName: transaction.cashierName ?? "Kasir",
            referenceType: "transaction",
            referenceId: transaction.id,
            createdAt: new Date(),
          });
        }

        await tx
          .update(transactions)
          .set({
            status: "voided",
            paymentStatus: "voided",
            voidReason: String(payload.reason ?? "").trim() || "Dibatalkan",
            updatedAt: new Date(),
          })
          .where(eq(transactions.id, id));
      });

      return { ok: true };
    }

    case "settings.update": {
      const patch = payload as Partial<BusinessSettings>;
      const existing = await db
        .select()
        .from(businessSettings)
        .where(eq(businessSettings.id, "default"))
        .limit(1);

      const current = existing[0];
      const values = {
        businessName:
          patch.businessName ??
          current?.businessName ??
          BUSINESS_SETTINGS.businessName,
        address: patch.address ?? current?.address ?? "",
        phone: patch.phone ?? current?.phone ?? "",
        email: patch.email ?? current?.email ?? "",
        currency: patch.currency ?? current?.currency ?? "IDR",
        timezone: patch.timezone ?? current?.timezone ?? "Asia/Jakarta",
        taxRate: String(patch.taxRate ?? current?.taxRate ?? 0),
        memberDiscountRate: String(
          patch.memberDiscountRate ?? current?.memberDiscountRate ?? 0
        ),
        lowStockThreshold:
          patch.lowStockThreshold ?? current?.lowStockThreshold ?? 10,
        updatedAt: new Date(),
      };

      if (existing.length > 0) {
        await db
          .update(businessSettings)
          .set(values)
          .where(eq(businessSettings.id, "default"));
      } else {
        await db.insert(businessSettings).values({
          id: "default",
          businessId: DEFAULT_BUSINESS_ID,
          ...values,
        });
      }

      const receiptExisting = await db
        .select()
        .from(receiptSettings)
        .where(
          and(
            eq(receiptSettings.businessId, DEFAULT_BUSINESS_ID),
            eq(receiptSettings.storeId, DEFAULT_STORE_ID)
          )
        )
        .limit(1);

      const footer =
        patch.receiptFooter ??
        receiptExisting[0]?.footer ??
        current?.legacyReceiptFooter ??
        "";

      if (receiptExisting.length > 0) {
        await db
          .update(receiptSettings)
          .set({ footer, updatedAt: new Date() })
          .where(eq(receiptSettings.id, receiptExisting[0].id));
      } else {
        await db.insert(receiptSettings).values({
          businessId: DEFAULT_BUSINESS_ID,
          storeId: DEFAULT_STORE_ID,
          footer,
          updatedAt: new Date(),
        });
      }

      return { ok: true };
    }

    default:
      throw new Error(`Aksi tidak dikenal: ${action}`);
  }
}
