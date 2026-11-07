import { test, expect } from "bun:test";
import { eq } from "drizzle-orm";

import { getBusinessData, mutateBusiness } from "@/server/business/service";
import { db } from "@/server/db";
import {
  categories,
  checkoutIdempotency,
  inventory,
  products,
  stockAdjustments,
  stockMovements,
} from "@/server/db/schema";
import type { ActingUser } from "@/server/business/service";

const hasIsolatedTestDatabase =
  Boolean(process.env.WARJOK_TEST_DATABASE_URL) &&
  process.env.WARJOK_TEST_DATABASE_URL !== process.env.DATABASE_URL;
const databaseTest = hasIsolatedTestDatabase ? test : test.skip;

const ACTING: ActingUser = {
  actingUserId: "test-user",
  actingUserRole: "owner",
};

function uniqueId(prefix: string) {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
}

databaseTest("getBusinessData returns real database records", async () => {
  const data = await getBusinessData();

  expect(Array.isArray(data.categories)).toBe(true);
  expect(Array.isArray(data.products)).toBe(true);
  expect(Array.isArray(data.customers)).toBe(true);
  expect(Array.isArray(data.staff)).toBe(true);
  expect(Array.isArray(data.transactions)).toBe(true);
  expect(Array.isArray(data.movements)).toBe(true);
  expect(data.settings).toBeDefined();

  // Data harus ada di database (tidak kosong/mock).
  expect(data.categories.length).toBeGreaterThanOrEqual(1);
  expect(data.products.length).toBeGreaterThanOrEqual(1);
  expect(data.transactions.length).toBeGreaterThanOrEqual(1);

  const sampleProduct = data.products[0];
  expect(sampleProduct.id).toBeDefined();
  expect(sampleProduct.name).toBeDefined();
  expect(sampleProduct.sku).toBeDefined();
  expect(typeof sampleProduct.price).toBe("number");
  expect(typeof sampleProduct.stock).toBe("number");
});

databaseTest("getBusinessData supports server-side pagination", async () => {
  const page1 = await getBusinessData({ page: 1, pageSize: 2 });
  const page2 = await getBusinessData({ page: 2, pageSize: 2 });

  expect(page1.products.length).toBeGreaterThanOrEqual(1);
  expect(page2.products.length).toBeGreaterThanOrEqual(1);

  // Produk di halaman 1 dan 2 tidak boleh saling tumpang (jika cukup data).
  if (page1.products.length === 2 && page2.products.length === 2) {
    const ids1 = new Set(page1.products.map((p) => p.id));
    const ids2 = new Set(page2.products.map((p) => p.id));
    let overlap = 0;
    for (const id of ids2) {
      if (ids1.has(id)) overlap++;
    }
    expect(overlap).toBe(0);
  }
});

databaseTest("getBusinessData supports server-side search filter", async () => {
  const all = await getBusinessData({ pageSize: 100 });
  const name = all.products[0].name;
  const keyword = name.slice(0, 3);

  const filtered = await getBusinessData({ search: keyword, pageSize: 100 });
  expect(filtered.products.length).toBeGreaterThanOrEqual(1);

  for (const product of filtered.products) {
    expect(
      product.name.toLowerCase().includes(keyword.toLowerCase())
    ).toBe(true);
  }
});

databaseTest("category.create and category.delete via database", async () => {
  const id = uniqueId("cat-test");

  const createResult = await mutateBusiness(
    "category.create",
    {
      id,
      name: "Kategori Tes",
      description: "Dibuat oleh tes otomatis",
      status: "active",
    },
    ACTING
  );
  expect(createResult.ok).toBe(true);

  // Verifikasi tersimpan di database.
  const [row] = await db
    .select()
    .from(categories)
    .where(eq(categories.id, id))
    .limit(1);
  expect(row).toBeDefined();
  expect(row.name).toBe("Kategori Tes");

  const deleteResult = await mutateBusiness(
    "category.delete",
    { id },
    ACTING
  );
  expect(deleteResult.ok).toBe(true);

  const [deleted] = await db
    .select()
    .from(categories)
    .where(eq(categories.id, id))
    .limit(1);
  expect(deleted).toBeUndefined();
});

databaseTest("product.create, update, and delete via database", async () => {
  const id = uniqueId("prod-test");

  const createResult = await mutateBusiness(
    "product.create",
    {
      id,
      name: "Produk Tes",
      sku: `TEST-${Date.now()}`,
      barcode: "1234567890001",
      categoryId: null,
      price: 15000,
      cost: 5000,
      stock: 10,
      minStock: 2,
      unit: "pcs",
      imageUrl: null,
      status: "active",
    },
    ACTING
  );
  expect(createResult.ok).toBe(true);

  const [row] = await db
    .select()
    .from(products)
    .where(eq(products.id, id))
    .limit(1);
  expect(row).toBeDefined();
  expect(row.name).toBe("Produk Tes");
  expect(Number(row.sellingPrice)).toBe(15000);
  expect(row.stockQuantity).toBe(10);

  const updateResult = await mutateBusiness(
    "product.update",
    {
      id,
      name: "Produk Tes Diupdate",
      sku: row.sku,
      barcode: row.barcode ?? null,
      categoryId: null,
      price: 20000,
      cost: 6000,
      stock: 15,
      minStock: 3,
      unit: "pcs",
      imageUrl: null,
      status: "active",
    },
    ACTING
  );
  expect(updateResult.ok).toBe(true);

  const [updated] = await db
    .select()
    .from(products)
    .where(eq(products.id, id))
    .limit(1);
  expect(updated.name).toBe("Produk Tes Diupdate");
  expect(updated.stockQuantity).toBe(15);

  const deleteResult = await mutateBusiness("product.delete", { id }, ACTING);
  expect(deleteResult.ok).toBe(true);

  const [deleted] = await db
    .select()
    .from(products)
    .where(eq(products.id, id))
    .limit(1);
  expect(deleted).toBeUndefined();
});

databaseTest("stock.adjust updates product stock and records movement", async () => {
  const id = uniqueId("prod-stock");

  await mutateBusiness(
    "product.create",
    {
      id,
      name: "Produk Stok Tes",
      sku: `STOCK-${Date.now()}`,
      barcode: null,
      categoryId: null,
      price: 10000,
      cost: 4000,
      stock: 5,
      minStock: 1,
      unit: "pcs",
      imageUrl: null,
      status: "active",
    },
    ACTING
  );

  const adjustResult = await mutateBusiness(
    "stock.adjust",
    {
      productId: id,
      mode: "in",
      quantity: 10,
      note: "Restock tes",
      staff: "Tes Otomatis",
    },
    ACTING
  );
  expect(adjustResult.ok).toBe(true);

  const [row] = await db
    .select()
    .from(products)
    .where(eq(products.id, id))
    .limit(1);
  expect(row.stockQuantity).toBe(15);

  const movements = await db
    .select()
    .from(stockMovements)
    .where(eq(stockMovements.productId, id));
  expect(movements.length).toBeGreaterThanOrEqual(1);
  const last = movements[movements.length - 1];
  expect(last.movementType).toBe("in");
  expect(last.quantity).toBe(10);
  expect(last.stockAfter).toBe(15);

  // Produk dengan riwayat stok tidak boleh dihapus; bersihkan riwayat dulu.
  await db.delete(stockAdjustments).where(eq(stockAdjustments.productId, id));
  await db.delete(stockMovements).where(eq(stockMovements.productId, id));
  await db.delete(inventory).where(eq(inventory.productId, id));
  await db.delete(products).where(eq(products.id, id));
});

databaseTest("checkout idempotency key cleanup", async () => {
  const key = `idem-${uniqueId("key")}`;

  // Simpan idempotency key di database.
  await db.insert(checkoutIdempotency).values({
    key,
    requestHash: "hash-a",
    transactionId: null,
    response: null,
    expiresAt: new Date(Date.now() + 86400000),
  });

  const [row] = await db
    .select()
    .from(checkoutIdempotency)
    .where(eq(checkoutIdempotency.key, key))
    .limit(1);
  expect(row).toBeDefined();
  expect(row.requestHash).toBe("hash-a");

  await db.delete(checkoutIdempotency).where(eq(checkoutIdempotency.key, key));

  const [deleted] = await db
    .select()
    .from(checkoutIdempotency)
    .where(eq(checkoutIdempotency.key, key))
    .limit(1);
  expect(deleted).toBeUndefined();
});
