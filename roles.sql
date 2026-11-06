BEGIN;

INSERT INTO "core"."Roles" ("Code", "Name", "Description", "Rank", "IsSystem")
VALUES
  ('user', 'User', 'Akun dasar', 0, true),
  ('cashier', 'Kasir', 'Operasional kasir', 1, true),
  ('manager', 'Manager', 'Operasional toko', 2, true),
  ('admin', 'Admin', 'Administrasi bisnis', 3, true),
  ('owner', 'Owner', 'Pemilik bisnis', 4, true)
ON CONFLICT ("Code") DO NOTHING;

INSERT INTO "core"."Permissions" ("Code", "Name", "Description", "Module")
VALUES
  ('category.create', 'Buat kategori', 'Buat kategori', 'categories'),
  ('category.update', 'Ubah kategori', 'Ubah kategori', 'categories'),
  ('category.delete', 'Hapus kategori', 'Hapus kategori', 'categories'),
  ('product.create', 'Buat produk', 'Buat produk', 'products'),
  ('product.update', 'Ubah produk', 'Ubah produk', 'products'),
  ('product.status', 'Ubah status produk', 'Ubah status produk', 'products'),
  ('product.delete', 'Hapus produk', 'Hapus produk', 'products'),
  ('customer.create', 'Buat pelanggan', 'Buat pelanggan', 'customers'),
  ('customer.update', 'Ubah pelanggan', 'Ubah pelanggan', 'customers'),
  ('customer.delete', 'Hapus pelanggan', 'Hapus pelanggan', 'customers'),
  ('staff.create', 'Buat staf', 'Buat staf', 'staff'),
  ('staff.update', 'Ubah staf', 'Ubah staf', 'staff'),
  ('staff.delete', 'Hapus staf', 'Hapus staf', 'staff'),
  ('stock.adjust', 'Sesuaikan stok', 'Sesuaikan stok', 'inventory'),
  ('transaction.void', 'Batalkan transaksi', 'Batalkan transaksi', 'transactions'),
  ('settings.update', 'Ubah pengaturan', 'Ubah pengaturan', 'settings')
ON CONFLICT ("Code") DO NOTHING;

INSERT INTO "core"."RolePermissions" ("RoleCode", "PermissionCode")
VALUES
  ('cashier', 'stock.adjust'),

  ('manager', 'category.create'),
  ('manager', 'category.update'),
  ('manager', 'product.create'),
  ('manager', 'product.update'),
  ('manager', 'product.status'),
  ('manager', 'customer.create'),
  ('manager', 'customer.update'),
  ('manager', 'stock.adjust'),
  ('manager', 'transaction.void'),

  ('admin', 'category.create'),
  ('admin', 'category.update'),
  ('admin', 'category.delete'),
  ('admin', 'product.create'),
  ('admin', 'product.update'),
  ('admin', 'product.status'),
  ('admin', 'product.delete'),
  ('admin', 'customer.create'),
  ('admin', 'customer.update'),
  ('admin', 'customer.delete'),
  ('admin', 'staff.create'),
  ('admin', 'staff.update'),
  ('admin', 'stock.adjust'),
  ('admin', 'transaction.void'),
  ('admin', 'settings.update'),

  ('owner', 'category.create'),
  ('owner', 'category.update'),
  ('owner', 'category.delete'),
  ('owner', 'product.create'),
  ('owner', 'product.update'),
  ('owner', 'product.status'),
  ('owner', 'product.delete'),
  ('owner', 'customer.create'),
  ('owner', 'customer.update'),
  ('owner', 'customer.delete'),
  ('owner', 'staff.create'),
  ('owner', 'staff.update'),
  ('owner', 'staff.delete'),
  ('owner', 'stock.adjust'),
  ('owner', 'transaction.void'),
  ('owner', 'settings.update')
ON CONFLICT ("RoleCode", "PermissionCode") DO NOTHING;

COMMIT;
