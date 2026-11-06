import { pgSchema } from "drizzle-orm/pg-core";

/**
 * Schema organisasi database Warjok POS.
 *
 * Domain schemas — tabel bisnis dipisah per domain untuk struktur yang lebih rapi.
 *
 * Catatan: tabel aplikasi wajib menggunakan PascalCase.
 */
export const CORE_SCHEMA = "core";
export const PRODUCTS_SCHEMA = "products";
export const INVENTORY_SCHEMA = "inventory";
export const CUSTOMERS_SCHEMA = "customers";
export const STAFF_SCHEMA = "staff";
export const SUPPLIERS_SCHEMA = "suppliers";
export const PURCHASES_SCHEMA = "purchases";
export const TRANSACTIONS_SCHEMA = "transactions";
export const PAYMENTS_SCHEMA = "payments";
export const LOOKUPS_SCHEMA = "lookups";
export const SETTINGS_SCHEMA = "settings";
export const AUDIT_SCHEMA = "audit";

export const coreSchema = pgSchema(CORE_SCHEMA);
export const productsSchema = pgSchema(PRODUCTS_SCHEMA);
export const inventorySchema = pgSchema(INVENTORY_SCHEMA);
export const customersSchema = pgSchema(CUSTOMERS_SCHEMA);
export const staffSchema = pgSchema(STAFF_SCHEMA);
export const suppliersSchema = pgSchema(SUPPLIERS_SCHEMA);
export const purchasesSchema = pgSchema(PURCHASES_SCHEMA);
export const transactionsSchema = pgSchema(TRANSACTIONS_SCHEMA);
export const paymentsSchema = pgSchema(PAYMENTS_SCHEMA);
export const lookupsSchema = pgSchema(LOOKUPS_SCHEMA);
export const settingsSchema = pgSchema(SETTINGS_SCHEMA);
export const auditSchema = pgSchema(AUDIT_SCHEMA);

/**
 * Identitas bisnis dan toko default untuk instalasi single-business.
 * Nilai ini dipakai sebagai default kolom kepemilikan agar data lama tetap
 * valid saat migrasi. Multi-business dapat menambahkan baris baru dan
 * mengisi kolom BusinessId/StoreId secara eksplisit.
 */
export const DEFAULT_BUSINESS_ID = "00000000-0000-0000-0000-000000000001";
export const DEFAULT_STORE_ID = "00000000-0000-0000-0000-000000000002";
