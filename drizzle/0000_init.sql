CREATE SCHEMA IF NOT EXISTS "audit";
--> statement-breakpoint
CREATE SCHEMA IF NOT EXISTS "core";
--> statement-breakpoint
CREATE SCHEMA IF NOT EXISTS "customers";
--> statement-breakpoint
CREATE SCHEMA IF NOT EXISTS "inventory";
--> statement-breakpoint
CREATE SCHEMA IF NOT EXISTS "lookups";
--> statement-breakpoint
CREATE SCHEMA IF NOT EXISTS "payments";
--> statement-breakpoint
CREATE SCHEMA IF NOT EXISTS "products";
--> statement-breakpoint
CREATE SCHEMA IF NOT EXISTS "purchases";
--> statement-breakpoint
CREATE SCHEMA IF NOT EXISTS "settings";
--> statement-breakpoint
CREATE SCHEMA IF NOT EXISTS "staff";
--> statement-breakpoint
CREATE SCHEMA IF NOT EXISTS "suppliers";
--> statement-breakpoint
CREATE SCHEMA IF NOT EXISTS "transactions";
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "audit"."AuditLogs" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"UserId" text,
	"Action" text NOT NULL,
	"EntityType" text NOT NULL,
	"EntityId" text,
	"OldValues" jsonb,
	"NewValues" jsonb,
	"IpAddress" text,
	"UserAgent" text,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "audit"."FileAttachments" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"EntityType" text NOT NULL,
	"EntityId" text NOT NULL,
	"FileName" text NOT NULL,
	"MimeType" text NOT NULL,
	"SizeBytes" bigint DEFAULT 0 NOT NULL,
	"StorageProvider" text DEFAULT 'neon' NOT NULL,
	"StorageKey" text NOT NULL,
	"Url" text,
	"UploadedByUserId" text,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "audit"."Notifications" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"UserId" text,
	"Type" text NOT NULL,
	"Title" text NOT NULL,
	"Body" text NOT NULL,
	"ReadAt" timestamp with time zone,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "core"."BusinessMembers" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid NOT NULL,
	"UserId" text NOT NULL,
	"Role" text DEFAULT 'user' NOT NULL,
	"StoreId" uuid,
	"Status" text DEFAULT 'active' NOT NULL,
	"InvitedAt" timestamp with time zone,
	"JoinedAt" timestamp with time zone,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"DeletedAt" timestamp with time zone,
	CONSTRAINT "BusinessMembers_BusinessId_UserId_key" UNIQUE("BusinessId","UserId"),
	CONSTRAINT "BusinessMembers_Status_check" CHECK ("core"."BusinessMembers"."Status" in ('invited', 'active', 'suspended', 'removed'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "core"."Businesses" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"Name" text NOT NULL,
	"Slug" text NOT NULL,
	"LegalName" text,
	"TaxId" text,
	"Currency" text DEFAULT 'IDR' NOT NULL,
	"Timezone" text DEFAULT 'Asia/Jakarta' NOT NULL,
	"OwnerUserId" text,
	"Status" text DEFAULT 'active' NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"DeletedAt" timestamp with time zone,
	CONSTRAINT "Businesses_Slug_key" UNIQUE("Slug"),
	CONSTRAINT "Businesses_Status_check" CHECK ("core"."Businesses"."Status" in ('active', 'suspended', 'archived'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "core"."Permissions" (
	"Code" text PRIMARY KEY NOT NULL,
	"Name" text NOT NULL,
	"Description" text,
	"Module" text NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "Permissions_Name_key" UNIQUE("Name")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "core"."RolePermissions" (
	"RoleCode" text NOT NULL,
	"PermissionCode" text NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "RolePermissions_pkey" PRIMARY KEY("RoleCode","PermissionCode")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "core"."Roles" (
	"Code" text PRIMARY KEY NOT NULL,
	"Name" text NOT NULL,
	"Description" text,
	"Rank" integer DEFAULT 0 NOT NULL,
	"IsSystem" boolean DEFAULT true NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "Roles_Name_key" UNIQUE("Name"),
	CONSTRAINT "Roles_Rank_check" CHECK ("core"."Roles"."Rank" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "core"."Stores" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid NOT NULL,
	"Name" text NOT NULL,
	"Code" text NOT NULL,
	"Address" text,
	"Phone" text,
	"Email" text,
	"Timezone" text DEFAULT 'Asia/Jakarta' NOT NULL,
	"IsActive" boolean DEFAULT true NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"DeletedAt" timestamp with time zone,
	CONSTRAINT "Stores_BusinessId_Code_key" UNIQUE("BusinessId","Code")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "core"."UserProfiles" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"UserId" text NOT NULL,
	"Name" text,
	"Email" text,
	"Role" text DEFAULT 'user' NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"DeletedAt" timestamp with time zone,
	CONSTRAINT "UserProfiles_UserId_key" UNIQUE("UserId")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "customers"."CustomerAddresses" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"CustomerId" text NOT NULL,
	"Label" text DEFAULT 'Utama' NOT NULL,
	"RecipientName" text,
	"Phone" text,
	"AddressLine1" text NOT NULL,
	"AddressLine2" text,
	"City" text,
	"Province" text,
	"PostalCode" text,
	"Country" text DEFAULT 'Indonesia' NOT NULL,
	"IsPrimary" boolean DEFAULT false NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "customers"."Customers" (
	"Id" text PRIMARY KEY NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"Name" text NOT NULL,
	"Phone" text NOT NULL,
	"Email" text,
	"Notes" text,
	"LoyaltyPoints" integer DEFAULT 0 NOT NULL,
	"JoinedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"DeletedAt" timestamp with time zone,
	CONSTRAINT "Customers_LoyaltyPoints_check" CHECK ("customers"."Customers"."LoyaltyPoints" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "products"."Categories" (
	"Id" text PRIMARY KEY NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"ParentCategoryId" text,
	"Name" text NOT NULL,
	"Description" text,
	"SortOrder" integer DEFAULT 0 NOT NULL,
	"Status" text DEFAULT 'active' NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"DeletedAt" timestamp with time zone,
	CONSTRAINT "Categories_Status_check" CHECK ("products"."Categories"."Status" in ('active', 'archived'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "products"."ProductBarcodes" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"ProductId" text NOT NULL,
	"Barcode" text NOT NULL,
	"IsPrimary" boolean DEFAULT false NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "ProductBarcodes_Barcode_key" UNIQUE("Barcode")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "products"."ProductPrices" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"ProductId" text NOT NULL,
	"StoreId" uuid,
	"PriceType" text DEFAULT 'retail' NOT NULL,
	"SellingPrice" numeric(14, 2) DEFAULT '0' NOT NULL,
	"CostPrice" numeric(14, 2) DEFAULT '0' NOT NULL,
	"StartsAt" timestamp with time zone,
	"EndsAt" timestamp with time zone,
	"IsActive" boolean DEFAULT true NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "ProductPrices_PriceType_check" CHECK ("products"."ProductPrices"."PriceType" in ('retail', 'wholesale', 'member')),
	CONSTRAINT "ProductPrices_SellingPrice_check" CHECK ("products"."ProductPrices"."SellingPrice" >= 0),
	CONSTRAINT "ProductPrices_CostPrice_check" CHECK ("products"."ProductPrices"."CostPrice" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "products"."ProductUnits" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"ProductId" text NOT NULL,
	"Name" text NOT NULL,
	"Abbreviation" text NOT NULL,
	"ConversionFactor" numeric(12, 4) DEFAULT '1' NOT NULL,
	"IsBase" boolean DEFAULT false NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "ProductUnits_ProductId_Name_key" UNIQUE("ProductId","Name"),
	CONSTRAINT "ProductUnits_ConversionFactor_check" CHECK ("products"."ProductUnits"."ConversionFactor" > 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "products"."ProductVariants" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"ProductId" text NOT NULL,
	"Name" text NOT NULL,
	"Sku" text NOT NULL,
	"Barcode" text,
	"SellingPrice" numeric(14, 2),
	"CostPrice" numeric(14, 2),
	"IsActive" boolean DEFAULT true NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "ProductVariants_BusinessId_Sku_key" UNIQUE("BusinessId","Sku")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "products"."Products" (
	"Id" text PRIMARY KEY NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"CategoryId" text,
	"Name" text NOT NULL,
	"Description" text,
	"Sku" text NOT NULL,
	"Barcode" text,
	"SellingPrice" numeric(14, 2) DEFAULT '0' NOT NULL,
	"CostPrice" numeric(14, 2) DEFAULT '0' NOT NULL,
	"StockQuantity" integer DEFAULT 0 NOT NULL,
	"MinimumStock" integer DEFAULT 0 NOT NULL,
	"Unit" text DEFAULT 'pcs' NOT NULL,
	"ImageUrl" text,
	"IsTaxable" boolean DEFAULT true NOT NULL,
	"IsStockTracked" boolean DEFAULT true NOT NULL,
	"Status" text DEFAULT 'active' NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"ArchivedAt" timestamp with time zone,
	"DeletedAt" timestamp with time zone,
	CONSTRAINT "Products_BusinessId_Sku_key" UNIQUE("BusinessId","Sku"),
	CONSTRAINT "Products_Status_check" CHECK ("products"."Products"."Status" in ('active', 'archived', 'discontinued')),
	CONSTRAINT "Products_SellingPrice_check" CHECK ("products"."Products"."SellingPrice" >= 0),
	CONSTRAINT "Products_CostPrice_check" CHECK ("products"."Products"."CostPrice" >= 0),
	CONSTRAINT "Products_StockQuantity_check" CHECK ("products"."Products"."StockQuantity" >= 0),
	CONSTRAINT "Products_MinimumStock_check" CHECK ("products"."Products"."MinimumStock" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "inventory"."Inventory" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"StoreId" uuid DEFAULT '00000000-0000-0000-0000-000000000002' NOT NULL,
	"ProductId" text NOT NULL,
	"StockQuantity" integer DEFAULT 0 NOT NULL,
	"ReservedQuantity" integer DEFAULT 0 NOT NULL,
	"MinimumStock" integer DEFAULT 0 NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "Inventory_ProductId_StoreId_key" UNIQUE("ProductId","StoreId"),
	CONSTRAINT "Inventory_StockQuantity_check" CHECK ("inventory"."Inventory"."StockQuantity" >= 0),
	CONSTRAINT "Inventory_ReservedQuantity_check" CHECK ("inventory"."Inventory"."ReservedQuantity" >= 0),
	CONSTRAINT "Inventory_MinimumStock_check" CHECK ("inventory"."Inventory"."MinimumStock" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "inventory"."StockAdjustments" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"StoreId" uuid DEFAULT '00000000-0000-0000-0000-000000000002' NOT NULL,
	"ProductId" text NOT NULL,
	"AdjustmentType" text NOT NULL,
	"Quantity" integer NOT NULL,
	"Reason" text NOT NULL,
	"Notes" text,
	"AdjustedByUserId" text,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "StockAdjustments_Quantity_check" CHECK ("inventory"."StockAdjustments"."Quantity" >= 0),
	CONSTRAINT "StockAdjustments_AdjustmentType_check" CHECK ("inventory"."StockAdjustments"."AdjustmentType" in ('increase', 'decrease', 'set'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "inventory"."StockMovements" (
	"Id" text PRIMARY KEY NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"StoreId" uuid DEFAULT '00000000-0000-0000-0000-000000000002' NOT NULL,
	"ProductId" text,
	"ProductName" text NOT NULL,
	"MovementType" text NOT NULL,
	"Quantity" integer NOT NULL,
	"StockAfter" integer NOT NULL,
	"UnitCost" numeric(14, 2),
	"Note" text,
	"StaffId" text,
	"StaffName" text,
	"ReferenceType" text,
	"ReferenceId" text,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "StockMovements_StockAfter_check" CHECK ("inventory"."StockMovements"."StockAfter" >= 0),
	CONSTRAINT "StockMovements_MovementType_check" CHECK ("inventory"."StockMovements"."MovementType" in ('in', 'out', 'adjustment', 'sale', 'void', 'return', 'purchase', 'transfer'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "lookups"."Discounts" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"Name" text NOT NULL,
	"Code" text NOT NULL,
	"Type" text DEFAULT 'fixed' NOT NULL,
	"Value" numeric(14, 2) DEFAULT '0' NOT NULL,
	"IsActive" boolean DEFAULT true NOT NULL,
	"StartsAt" timestamp with time zone,
	"EndsAt" timestamp with time zone,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "Discounts_BusinessId_Code_key" UNIQUE("BusinessId","Code"),
	CONSTRAINT "Discounts_Type_check" CHECK ("lookups"."Discounts"."Type" in ('percentage', 'fixed')),
	CONSTRAINT "Discounts_Value_check" CHECK ("lookups"."Discounts"."Value" >= 0),
	CONSTRAINT "Discounts_PercentageValue_check" CHECK ("lookups"."Discounts"."Type" <> 'percentage' or "lookups"."Discounts"."Value" <= 100)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "lookups"."PaymentMethods" (
	"Code" text PRIMARY KEY NOT NULL,
	"Name" text NOT NULL,
	"IsActive" boolean DEFAULT true NOT NULL,
	"RequiresReference" boolean DEFAULT false NOT NULL,
	"SortOrder" integer DEFAULT 0 NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "lookups"."TaxRates" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"Name" text NOT NULL,
	"Rate" numeric(5, 4) DEFAULT '0' NOT NULL,
	"IsDefault" boolean DEFAULT false NOT NULL,
	"IsActive" boolean DEFAULT true NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "TaxRates_BusinessId_Name_key" UNIQUE("BusinessId","Name"),
	CONSTRAINT "TaxRates_Rate_check" CHECK ("lookups"."TaxRates"."Rate" >= 0 and "lookups"."TaxRates"."Rate" <= 1)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "staff"."CashMovements" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"SessionId" uuid NOT NULL,
	"MovementType" text NOT NULL,
	"Amount" numeric(14, 2) NOT NULL,
	"Reason" text NOT NULL,
	"StaffId" text,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "CashMovements_MovementType_check" CHECK ("staff"."CashMovements"."MovementType" in ('in', 'out')),
	CONSTRAINT "CashMovements_Amount_check" CHECK ("staff"."CashMovements"."Amount" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "staff"."CashRegisterSessions" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"CashRegisterId" uuid NOT NULL,
	"StoreId" uuid NOT NULL,
	"OpenedByStaffId" text NOT NULL,
	"ClosedByStaffId" text,
	"OpeningBalance" numeric(14, 2) DEFAULT '0' NOT NULL,
	"ClosingBalance" numeric(14, 2),
	"ExpectedBalance" numeric(14, 2),
	"Difference" numeric(14, 2),
	"Status" text DEFAULT 'open' NOT NULL,
	"OpenedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"ClosedAt" timestamp with time zone,
	"Notes" text,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "CashRegisterSessions_Status_check" CHECK ("staff"."CashRegisterSessions"."Status" in ('open', 'closed', 'voided')),
	CONSTRAINT "CashRegisterSessions_OpeningBalance_check" CHECK ("staff"."CashRegisterSessions"."OpeningBalance" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "staff"."CashRegisters" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"StoreId" uuid NOT NULL,
	"Name" text NOT NULL,
	"Code" text NOT NULL,
	"IsActive" boolean DEFAULT true NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "CashRegisters_StoreId_Code_key" UNIQUE("StoreId","Code")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "staff"."Shifts" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"StoreId" uuid NOT NULL,
	"StaffId" text NOT NULL,
	"StartTime" timestamp with time zone NOT NULL,
	"EndTime" timestamp with time zone,
	"Status" text DEFAULT 'scheduled' NOT NULL,
	"Notes" text,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "Shifts_Status_check" CHECK ("staff"."Shifts"."Status" in ('scheduled', 'active', 'completed', 'cancelled'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "staff"."Staff" (
	"Id" text PRIMARY KEY NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"StoreId" uuid,
	"UserId" text,
	"Name" text NOT NULL,
	"Email" text NOT NULL,
	"Role" text DEFAULT 'cashier' NOT NULL,
	"Status" text DEFAULT 'active' NOT NULL,
	"JoinedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"LastActive" timestamp with time zone,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"DeletedAt" timestamp with time zone,
	CONSTRAINT "Staff_BusinessId_Email_key" UNIQUE("BusinessId","Email"),
	CONSTRAINT "Staff_Status_check" CHECK ("staff"."Staff"."Status" in ('active', 'inactive', 'suspended'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "suppliers"."Suppliers" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"Name" text NOT NULL,
	"ContactName" text,
	"Phone" text,
	"Email" text,
	"Address" text,
	"TaxId" text,
	"Notes" text,
	"Status" text DEFAULT 'active' NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"DeletedAt" timestamp with time zone,
	CONSTRAINT "Suppliers_Status_check" CHECK ("suppliers"."Suppliers"."Status" in ('active', 'inactive', 'archived'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "purchases"."GoodsReceiptItems" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"GoodsReceiptId" uuid NOT NULL,
	"PurchaseOrderItemId" uuid NOT NULL,
	"ProductId" text NOT NULL,
	"QuantityReceived" integer NOT NULL,
	"UnitCost" numeric(14, 2) DEFAULT '0' NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "GoodsReceiptItems_QuantityReceived_check" CHECK ("purchases"."GoodsReceiptItems"."QuantityReceived" > 0),
	CONSTRAINT "GoodsReceiptItems_UnitCost_check" CHECK ("purchases"."GoodsReceiptItems"."UnitCost" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "purchases"."GoodsReceipts" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"PurchaseOrderId" uuid NOT NULL,
	"ReceiptNumber" text NOT NULL,
	"ReceivedByUserId" text,
	"ReceivedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"Notes" text,
	"Status" text DEFAULT 'received' NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "GoodsReceipts_ReceiptNumber_key" UNIQUE("ReceiptNumber"),
	CONSTRAINT "GoodsReceipts_Status_check" CHECK ("purchases"."GoodsReceipts"."Status" in ('draft', 'received', 'voided'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "purchases"."PurchaseOrderItems" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"PurchaseOrderId" uuid NOT NULL,
	"ProductId" text NOT NULL,
	"ProductName" text NOT NULL,
	"Sku" text,
	"QuantityOrdered" integer NOT NULL,
	"QuantityReceived" integer DEFAULT 0 NOT NULL,
	"UnitCost" numeric(14, 2) DEFAULT '0' NOT NULL,
	"LineTotal" numeric(14, 2) DEFAULT '0' NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "PurchaseOrderItems_QuantityOrdered_check" CHECK ("purchases"."PurchaseOrderItems"."QuantityOrdered" > 0),
	CONSTRAINT "PurchaseOrderItems_QuantityReceived_check" CHECK ("purchases"."PurchaseOrderItems"."QuantityReceived" >= 0),
	CONSTRAINT "PurchaseOrderItems_UnitCost_check" CHECK ("purchases"."PurchaseOrderItems"."UnitCost" >= 0),
	CONSTRAINT "PurchaseOrderItems_LineTotal_check" CHECK ("purchases"."PurchaseOrderItems"."LineTotal" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "purchases"."PurchaseOrders" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"StoreId" uuid NOT NULL,
	"SupplierId" uuid NOT NULL,
	"OrderNumber" text NOT NULL,
	"Status" text DEFAULT 'draft' NOT NULL,
	"OrderDate" timestamp with time zone DEFAULT now() NOT NULL,
	"ExpectedDate" timestamp with time zone,
	"Subtotal" numeric(14, 2) DEFAULT '0' NOT NULL,
	"TaxTotal" numeric(14, 2) DEFAULT '0' NOT NULL,
	"GrandTotal" numeric(14, 2) DEFAULT '0' NOT NULL,
	"Notes" text,
	"CreatedByUserId" text,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "PurchaseOrders_OrderNumber_key" UNIQUE("OrderNumber"),
	CONSTRAINT "PurchaseOrders_Status_check" CHECK ("purchases"."PurchaseOrders"."Status" in ('draft', 'ordered', 'partial', 'received', 'cancelled')),
	CONSTRAINT "PurchaseOrders_Subtotal_check" CHECK ("purchases"."PurchaseOrders"."Subtotal" >= 0),
	CONSTRAINT "PurchaseOrders_TaxTotal_check" CHECK ("purchases"."PurchaseOrders"."TaxTotal" >= 0),
	CONSTRAINT "PurchaseOrders_GrandTotal_check" CHECK ("purchases"."PurchaseOrders"."GrandTotal" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "transactions"."CheckoutIdempotency" (
	"Key" text PRIMARY KEY NOT NULL,
	"RequestHash" text NOT NULL,
	"TransactionId" text,
	"Response" text,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"ExpiresAt" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "transactions"."TransactionItems" (
	"Id" text PRIMARY KEY NOT NULL,
	"TransactionId" text NOT NULL,
	"ProductId" text NOT NULL,
	"ProductVariantId" uuid,
	"ProductName" text NOT NULL,
	"Sku" text,
	"Quantity" integer NOT NULL,
	"UnitPrice" numeric(14, 2) NOT NULL,
	"DiscountTotal" numeric(14, 2) DEFAULT '0' NOT NULL,
	"TaxTotal" numeric(14, 2) DEFAULT '0' NOT NULL,
	"LineTotal" numeric(14, 2) NOT NULL,
	"CostPrice" numeric(14, 2) DEFAULT '0' NOT NULL,
	"Notes" text,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "TransactionItems_Quantity_check" CHECK ("transactions"."TransactionItems"."Quantity" > 0),
	CONSTRAINT "TransactionItems_UnitPrice_check" CHECK ("transactions"."TransactionItems"."UnitPrice" >= 0),
	CONSTRAINT "TransactionItems_DiscountTotal_check" CHECK ("transactions"."TransactionItems"."DiscountTotal" >= 0),
	CONSTRAINT "TransactionItems_TaxTotal_check" CHECK ("transactions"."TransactionItems"."TaxTotal" >= 0),
	CONSTRAINT "TransactionItems_LineTotal_check" CHECK ("transactions"."TransactionItems"."LineTotal" >= 0),
	CONSTRAINT "TransactionItems_CostPrice_check" CHECK ("transactions"."TransactionItems"."CostPrice" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "transactions"."Transactions" (
	"Id" text PRIMARY KEY NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"StoreId" uuid DEFAULT '00000000-0000-0000-0000-000000000002' NOT NULL,
	"TransactionNumber" text NOT NULL,
	"CashierId" text,
	"CashierName" text,
	"StaffId" text,
	"CustomerId" text,
	"CustomerName" text,
	"OrderType" text DEFAULT 'dine-in' NOT NULL,
	"TableNumber" text,
	"PaymentMethod" text NOT NULL,
	"PaymentStatus" text DEFAULT 'paid' NOT NULL,
	"TaxRateId" uuid,
	"Subtotal" numeric(14, 2) NOT NULL,
	"DiscountTotal" numeric(14, 2) DEFAULT '0' NOT NULL,
	"TaxTotal" numeric(14, 2) DEFAULT '0' NOT NULL,
	"GrandTotal" numeric(14, 2) NOT NULL,
	"AmountPaid" numeric(14, 2),
	"ChangeAmount" numeric(14, 2),
	"Status" text DEFAULT 'completed' NOT NULL,
	"VoidReason" text,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "Transactions_TransactionNumber_key" UNIQUE("TransactionNumber"),
	CONSTRAINT "Transactions_OrderType_check" CHECK ("transactions"."Transactions"."OrderType" in ('dine-in', 'takeaway', 'delivery')),
	CONSTRAINT "Transactions_Status_check" CHECK ("transactions"."Transactions"."Status" in ('completed', 'voided', 'refunded')),
	CONSTRAINT "Transactions_PaymentStatus_check" CHECK ("transactions"."Transactions"."PaymentStatus" in ('unpaid', 'partial', 'paid', 'refunded', 'voided')),
	CONSTRAINT "Transactions_Subtotal_check" CHECK ("transactions"."Transactions"."Subtotal" >= 0),
	CONSTRAINT "Transactions_DiscountTotal_check" CHECK ("transactions"."Transactions"."DiscountTotal" >= 0),
	CONSTRAINT "Transactions_TaxTotal_check" CHECK ("transactions"."Transactions"."TaxTotal" >= 0),
	CONSTRAINT "Transactions_GrandTotal_check" CHECK ("transactions"."Transactions"."GrandTotal" >= 0),
	CONSTRAINT "Transactions_AmountPaid_check" CHECK ("transactions"."Transactions"."AmountPaid" is null or "transactions"."Transactions"."AmountPaid" >= 0),
	CONSTRAINT "Transactions_ChangeAmount_check" CHECK ("transactions"."Transactions"."ChangeAmount" is null or "transactions"."Transactions"."ChangeAmount" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "payments"."Payments" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"TransactionId" text NOT NULL,
	"PaymentMethod" text NOT NULL,
	"Amount" numeric(14, 2) NOT NULL,
	"ReferenceNumber" text,
	"Status" text DEFAULT 'completed' NOT NULL,
	"PaidAt" timestamp with time zone DEFAULT now() NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "Payments_Amount_check" CHECK ("payments"."Payments"."Amount" >= 0),
	CONSTRAINT "Payments_Status_check" CHECK ("payments"."Payments"."Status" in ('pending', 'completed', 'failed', 'refunded'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "payments"."TransactionDiscounts" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"TransactionId" text NOT NULL,
	"DiscountId" uuid,
	"Name" text NOT NULL,
	"Type" text DEFAULT 'fixed' NOT NULL,
	"Value" numeric(14, 2) DEFAULT '0' NOT NULL,
	"Amount" numeric(14, 2) DEFAULT '0' NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "TransactionDiscounts_Type_check" CHECK ("payments"."TransactionDiscounts"."Type" in ('percentage', 'fixed')),
	CONSTRAINT "TransactionDiscounts_Value_check" CHECK ("payments"."TransactionDiscounts"."Value" >= 0),
	CONSTRAINT "TransactionDiscounts_Amount_check" CHECK ("payments"."TransactionDiscounts"."Amount" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "payments"."TransactionRefundItems" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"RefundId" uuid NOT NULL,
	"TransactionItemId" text NOT NULL,
	"ProductId" text NOT NULL,
	"Quantity" integer NOT NULL,
	"UnitPrice" numeric(14, 2) NOT NULL,
	"LineTotal" numeric(14, 2) NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "TransactionRefundItems_Quantity_check" CHECK ("payments"."TransactionRefundItems"."Quantity" > 0),
	CONSTRAINT "TransactionRefundItems_UnitPrice_check" CHECK ("payments"."TransactionRefundItems"."UnitPrice" >= 0),
	CONSTRAINT "TransactionRefundItems_LineTotal_check" CHECK ("payments"."TransactionRefundItems"."LineTotal" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "payments"."TransactionRefunds" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"TransactionId" text NOT NULL,
	"RefundNumber" text NOT NULL,
	"Amount" numeric(14, 2) NOT NULL,
	"Reason" text NOT NULL,
	"Status" text DEFAULT 'completed' NOT NULL,
	"RefundedByUserId" text,
	"RefundedAt" timestamp with time zone,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "TransactionRefunds_RefundNumber_key" UNIQUE("RefundNumber"),
	CONSTRAINT "TransactionRefunds_Amount_check" CHECK ("payments"."TransactionRefunds"."Amount" >= 0),
	CONSTRAINT "TransactionRefunds_Status_check" CHECK ("payments"."TransactionRefunds"."Status" in ('pending', 'completed', 'rejected'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "settings"."BusinessSettings" (
	"Id" text PRIMARY KEY DEFAULT 'default' NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"BusinessName" text NOT NULL,
	"Address" text DEFAULT '' NOT NULL,
	"Phone" text DEFAULT '' NOT NULL,
	"Email" text DEFAULT '' NOT NULL,
	"Currency" text DEFAULT 'IDR' NOT NULL,
	"Timezone" text DEFAULT 'Asia/Jakarta' NOT NULL,
	"TaxRate" numeric(5, 4) DEFAULT '0' NOT NULL,
	"MemberDiscountRate" numeric(5, 4) DEFAULT '0' NOT NULL,
	"LowStockThreshold" integer DEFAULT 10 NOT NULL,
	"LegacyReceiptFooter" text DEFAULT '' NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "BusinessSettings_TaxRate_check" CHECK ("settings"."BusinessSettings"."TaxRate" >= 0 and "settings"."BusinessSettings"."TaxRate" <= 1),
	CONSTRAINT "BusinessSettings_MemberDiscountRate_check" CHECK ("settings"."BusinessSettings"."MemberDiscountRate" >= 0 and "settings"."BusinessSettings"."MemberDiscountRate" <= 1),
	CONSTRAINT "BusinessSettings_LowStockThreshold_check" CHECK ("settings"."BusinessSettings"."LowStockThreshold" >= 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "settings"."ReceiptSettings" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"StoreId" uuid,
	"Header" text DEFAULT '' NOT NULL,
	"Footer" text DEFAULT '' NOT NULL,
	"ShowTax" boolean DEFAULT true NOT NULL,
	"ShowCashier" boolean DEFAULT true NOT NULL,
	"PaperWidth" integer DEFAULT 58 NOT NULL,
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "ReceiptSettings_PaperWidth_check" CHECK ("settings"."ReceiptSettings"."PaperWidth" in (58, 80))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "settings"."StoreSettings" (
	"Id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"BusinessId" uuid DEFAULT '00000000-0000-0000-0000-000000000001' NOT NULL,
	"StoreId" uuid NOT NULL,
	"LowStockThreshold" integer,
	"TaxRate" numeric(5, 4),
	"CreatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	"UpdatedAt" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "StoreSettings_StoreId_key" UNIQUE("StoreId"),
	CONSTRAINT "StoreSettings_TaxRate_check" CHECK ("settings"."StoreSettings"."TaxRate" is null or ("settings"."StoreSettings"."TaxRate" >= 0 and "settings"."StoreSettings"."TaxRate" <= 1)),
	CONSTRAINT "StoreSettings_LowStockThreshold_check" CHECK ("settings"."StoreSettings"."LowStockThreshold" is null or "settings"."StoreSettings"."LowStockThreshold" >= 0)
);
--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'AuditLogs_BusinessId_Businesses_Id_fk' AND conrelid = '"audit"."AuditLogs"'::regclass) THEN
		ALTER TABLE "audit"."AuditLogs" ADD CONSTRAINT "AuditLogs_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FileAttachments_BusinessId_Businesses_Id_fk' AND conrelid = '"audit"."FileAttachments"'::regclass) THEN
		ALTER TABLE "audit"."FileAttachments" ADD CONSTRAINT "FileAttachments_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Notifications_BusinessId_Businesses_Id_fk' AND conrelid = '"audit"."Notifications"'::regclass) THEN
		ALTER TABLE "audit"."Notifications" ADD CONSTRAINT "Notifications_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'BusinessMembers_BusinessId_Businesses_Id_fk' AND conrelid = '"core"."BusinessMembers"'::regclass) THEN
		ALTER TABLE "core"."BusinessMembers" ADD CONSTRAINT "BusinessMembers_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'BusinessMembers_Role_Roles_Code_fk' AND conrelid = '"core"."BusinessMembers"'::regclass) THEN
		ALTER TABLE "core"."BusinessMembers" ADD CONSTRAINT "BusinessMembers_Role_Roles_Code_fk" FOREIGN KEY ("Role") REFERENCES "core"."Roles"("Code") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'BusinessMembers_StoreId_Stores_Id_fk' AND conrelid = '"core"."BusinessMembers"'::regclass) THEN
		ALTER TABLE "core"."BusinessMembers" ADD CONSTRAINT "BusinessMembers_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'RolePermissions_RoleCode_Roles_Code_fk' AND conrelid = '"core"."RolePermissions"'::regclass) THEN
		ALTER TABLE "core"."RolePermissions" ADD CONSTRAINT "RolePermissions_RoleCode_Roles_Code_fk" FOREIGN KEY ("RoleCode") REFERENCES "core"."Roles"("Code") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'RolePermissions_PermissionCode_Permissions_Code_fk' AND conrelid = '"core"."RolePermissions"'::regclass) THEN
		ALTER TABLE "core"."RolePermissions" ADD CONSTRAINT "RolePermissions_PermissionCode_Permissions_Code_fk" FOREIGN KEY ("PermissionCode") REFERENCES "core"."Permissions"("Code") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Stores_BusinessId_Businesses_Id_fk' AND conrelid = '"core"."Stores"'::regclass) THEN
		ALTER TABLE "core"."Stores" ADD CONSTRAINT "Stores_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'UserProfiles_Role_Roles_Code_fk' AND conrelid = '"core"."UserProfiles"'::regclass) THEN
		ALTER TABLE "core"."UserProfiles" ADD CONSTRAINT "UserProfiles_Role_Roles_Code_fk" FOREIGN KEY ("Role") REFERENCES "core"."Roles"("Code") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'CustomerAddresses_CustomerId_Customers_Id_fk' AND conrelid = '"customers"."CustomerAddresses"'::regclass) THEN
		ALTER TABLE "customers"."CustomerAddresses" ADD CONSTRAINT "CustomerAddresses_CustomerId_Customers_Id_fk" FOREIGN KEY ("CustomerId") REFERENCES "customers"."Customers"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Customers_BusinessId_Businesses_Id_fk' AND conrelid = '"customers"."Customers"'::regclass) THEN
		ALTER TABLE "customers"."Customers" ADD CONSTRAINT "Customers_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Categories_BusinessId_Businesses_Id_fk' AND conrelid = '"products"."Categories"'::regclass) THEN
		ALTER TABLE "products"."Categories" ADD CONSTRAINT "Categories_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Categories_ParentCategoryId_Categories_Id_fk' AND conrelid = '"products"."Categories"'::regclass) THEN
		ALTER TABLE "products"."Categories" ADD CONSTRAINT "Categories_ParentCategoryId_Categories_Id_fk" FOREIGN KEY ("ParentCategoryId") REFERENCES "products"."Categories"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ProductBarcodes_ProductId_Products_Id_fk' AND conrelid = '"products"."ProductBarcodes"'::regclass) THEN
		ALTER TABLE "products"."ProductBarcodes" ADD CONSTRAINT "ProductBarcodes_ProductId_Products_Id_fk" FOREIGN KEY ("ProductId") REFERENCES "products"."Products"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ProductPrices_ProductId_Products_Id_fk' AND conrelid = '"products"."ProductPrices"'::regclass) THEN
		ALTER TABLE "products"."ProductPrices" ADD CONSTRAINT "ProductPrices_ProductId_Products_Id_fk" FOREIGN KEY ("ProductId") REFERENCES "products"."Products"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ProductPrices_StoreId_Stores_Id_fk' AND conrelid = '"products"."ProductPrices"'::regclass) THEN
		ALTER TABLE "products"."ProductPrices" ADD CONSTRAINT "ProductPrices_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ProductUnits_ProductId_Products_Id_fk' AND conrelid = '"products"."ProductUnits"'::regclass) THEN
		ALTER TABLE "products"."ProductUnits" ADD CONSTRAINT "ProductUnits_ProductId_Products_Id_fk" FOREIGN KEY ("ProductId") REFERENCES "products"."Products"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ProductVariants_BusinessId_Businesses_Id_fk' AND conrelid = '"products"."ProductVariants"'::regclass) THEN
		ALTER TABLE "products"."ProductVariants" ADD CONSTRAINT "ProductVariants_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ProductVariants_ProductId_Products_Id_fk' AND conrelid = '"products"."ProductVariants"'::regclass) THEN
		ALTER TABLE "products"."ProductVariants" ADD CONSTRAINT "ProductVariants_ProductId_Products_Id_fk" FOREIGN KEY ("ProductId") REFERENCES "products"."Products"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Products_BusinessId_Businesses_Id_fk' AND conrelid = '"products"."Products"'::regclass) THEN
		ALTER TABLE "products"."Products" ADD CONSTRAINT "Products_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Products_CategoryId_Categories_Id_fk' AND conrelid = '"products"."Products"'::regclass) THEN
		ALTER TABLE "products"."Products" ADD CONSTRAINT "Products_CategoryId_Categories_Id_fk" FOREIGN KEY ("CategoryId") REFERENCES "products"."Categories"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Inventory_BusinessId_Businesses_Id_fk' AND conrelid = '"inventory"."Inventory"'::regclass) THEN
		ALTER TABLE "inventory"."Inventory" ADD CONSTRAINT "Inventory_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Inventory_StoreId_Stores_Id_fk' AND conrelid = '"inventory"."Inventory"'::regclass) THEN
		ALTER TABLE "inventory"."Inventory" ADD CONSTRAINT "Inventory_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Inventory_ProductId_Products_Id_fk' AND conrelid = '"inventory"."Inventory"'::regclass) THEN
		ALTER TABLE "inventory"."Inventory" ADD CONSTRAINT "Inventory_ProductId_Products_Id_fk" FOREIGN KEY ("ProductId") REFERENCES "products"."Products"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'StockAdjustments_BusinessId_Businesses_Id_fk' AND conrelid = '"inventory"."StockAdjustments"'::regclass) THEN
		ALTER TABLE "inventory"."StockAdjustments" ADD CONSTRAINT "StockAdjustments_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'StockAdjustments_StoreId_Stores_Id_fk' AND conrelid = '"inventory"."StockAdjustments"'::regclass) THEN
		ALTER TABLE "inventory"."StockAdjustments" ADD CONSTRAINT "StockAdjustments_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'StockAdjustments_ProductId_Products_Id_fk' AND conrelid = '"inventory"."StockAdjustments"'::regclass) THEN
		ALTER TABLE "inventory"."StockAdjustments" ADD CONSTRAINT "StockAdjustments_ProductId_Products_Id_fk" FOREIGN KEY ("ProductId") REFERENCES "products"."Products"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'StockMovements_BusinessId_Businesses_Id_fk' AND conrelid = '"inventory"."StockMovements"'::regclass) THEN
		ALTER TABLE "inventory"."StockMovements" ADD CONSTRAINT "StockMovements_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'StockMovements_StoreId_Stores_Id_fk' AND conrelid = '"inventory"."StockMovements"'::regclass) THEN
		ALTER TABLE "inventory"."StockMovements" ADD CONSTRAINT "StockMovements_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'StockMovements_ProductId_Products_Id_fk' AND conrelid = '"inventory"."StockMovements"'::regclass) THEN
		ALTER TABLE "inventory"."StockMovements" ADD CONSTRAINT "StockMovements_ProductId_Products_Id_fk" FOREIGN KEY ("ProductId") REFERENCES "products"."Products"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'StockMovements_StaffId_Staff_Id_fk' AND conrelid = '"inventory"."StockMovements"'::regclass) THEN
		ALTER TABLE "inventory"."StockMovements" ADD CONSTRAINT "StockMovements_StaffId_Staff_Id_fk" FOREIGN KEY ("StaffId") REFERENCES "staff"."Staff"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Discounts_BusinessId_Businesses_Id_fk' AND conrelid = '"lookups"."Discounts"'::regclass) THEN
		ALTER TABLE "lookups"."Discounts" ADD CONSTRAINT "Discounts_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'TaxRates_BusinessId_Businesses_Id_fk' AND conrelid = '"lookups"."TaxRates"'::regclass) THEN
		ALTER TABLE "lookups"."TaxRates" ADD CONSTRAINT "TaxRates_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'CashMovements_SessionId_CashRegisterSessions_Id_fk' AND conrelid = '"staff"."CashMovements"'::regclass) THEN
		ALTER TABLE "staff"."CashMovements" ADD CONSTRAINT "CashMovements_SessionId_CashRegisterSessions_Id_fk" FOREIGN KEY ("SessionId") REFERENCES "staff"."CashRegisterSessions"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'CashMovements_StaffId_Staff_Id_fk' AND conrelid = '"staff"."CashMovements"'::regclass) THEN
		ALTER TABLE "staff"."CashMovements" ADD CONSTRAINT "CashMovements_StaffId_Staff_Id_fk" FOREIGN KEY ("StaffId") REFERENCES "staff"."Staff"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'CashRegisterSessions_CashRegisterId_CashRegisters_Id_fk' AND conrelid = '"staff"."CashRegisterSessions"'::regclass) THEN
		ALTER TABLE "staff"."CashRegisterSessions" ADD CONSTRAINT "CashRegisterSessions_CashRegisterId_CashRegisters_Id_fk" FOREIGN KEY ("CashRegisterId") REFERENCES "staff"."CashRegisters"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'CashRegisterSessions_StoreId_Stores_Id_fk' AND conrelid = '"staff"."CashRegisterSessions"'::regclass) THEN
		ALTER TABLE "staff"."CashRegisterSessions" ADD CONSTRAINT "CashRegisterSessions_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'CashRegisterSessions_OpenedByStaffId_Staff_Id_fk' AND conrelid = '"staff"."CashRegisterSessions"'::regclass) THEN
		ALTER TABLE "staff"."CashRegisterSessions" ADD CONSTRAINT "CashRegisterSessions_OpenedByStaffId_Staff_Id_fk" FOREIGN KEY ("OpenedByStaffId") REFERENCES "staff"."Staff"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'CashRegisterSessions_ClosedByStaffId_Staff_Id_fk' AND conrelid = '"staff"."CashRegisterSessions"'::regclass) THEN
		ALTER TABLE "staff"."CashRegisterSessions" ADD CONSTRAINT "CashRegisterSessions_ClosedByStaffId_Staff_Id_fk" FOREIGN KEY ("ClosedByStaffId") REFERENCES "staff"."Staff"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'CashRegisters_BusinessId_Businesses_Id_fk' AND conrelid = '"staff"."CashRegisters"'::regclass) THEN
		ALTER TABLE "staff"."CashRegisters" ADD CONSTRAINT "CashRegisters_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'CashRegisters_StoreId_Stores_Id_fk' AND conrelid = '"staff"."CashRegisters"'::regclass) THEN
		ALTER TABLE "staff"."CashRegisters" ADD CONSTRAINT "CashRegisters_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Shifts_BusinessId_Businesses_Id_fk' AND conrelid = '"staff"."Shifts"'::regclass) THEN
		ALTER TABLE "staff"."Shifts" ADD CONSTRAINT "Shifts_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Shifts_StoreId_Stores_Id_fk' AND conrelid = '"staff"."Shifts"'::regclass) THEN
		ALTER TABLE "staff"."Shifts" ADD CONSTRAINT "Shifts_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Shifts_StaffId_Staff_Id_fk' AND conrelid = '"staff"."Shifts"'::regclass) THEN
		ALTER TABLE "staff"."Shifts" ADD CONSTRAINT "Shifts_StaffId_Staff_Id_fk" FOREIGN KEY ("StaffId") REFERENCES "staff"."Staff"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Staff_BusinessId_Businesses_Id_fk' AND conrelid = '"staff"."Staff"'::regclass) THEN
		ALTER TABLE "staff"."Staff" ADD CONSTRAINT "Staff_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Staff_StoreId_Stores_Id_fk' AND conrelid = '"staff"."Staff"'::regclass) THEN
		ALTER TABLE "staff"."Staff" ADD CONSTRAINT "Staff_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Staff_Role_Roles_Code_fk' AND conrelid = '"staff"."Staff"'::regclass) THEN
		ALTER TABLE "staff"."Staff" ADD CONSTRAINT "Staff_Role_Roles_Code_fk" FOREIGN KEY ("Role") REFERENCES "core"."Roles"("Code") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Suppliers_BusinessId_Businesses_Id_fk' AND conrelid = '"suppliers"."Suppliers"'::regclass) THEN
		ALTER TABLE "suppliers"."Suppliers" ADD CONSTRAINT "Suppliers_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'GoodsReceiptItems_GoodsReceiptId_GoodsReceipts_Id_fk' AND conrelid = '"purchases"."GoodsReceiptItems"'::regclass) THEN
		ALTER TABLE "purchases"."GoodsReceiptItems" ADD CONSTRAINT "GoodsReceiptItems_GoodsReceiptId_GoodsReceipts_Id_fk" FOREIGN KEY ("GoodsReceiptId") REFERENCES "purchases"."GoodsReceipts"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'GoodsReceiptItems_PurchaseOrderItemId_PurchaseOrderItems_Id_fk' AND conrelid = '"purchases"."GoodsReceiptItems"'::regclass) THEN
		ALTER TABLE "purchases"."GoodsReceiptItems" ADD CONSTRAINT "GoodsReceiptItems_PurchaseOrderItemId_PurchaseOrderItems_Id_fk" FOREIGN KEY ("PurchaseOrderItemId") REFERENCES "purchases"."PurchaseOrderItems"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'GoodsReceiptItems_ProductId_Products_Id_fk' AND conrelid = '"purchases"."GoodsReceiptItems"'::regclass) THEN
		ALTER TABLE "purchases"."GoodsReceiptItems" ADD CONSTRAINT "GoodsReceiptItems_ProductId_Products_Id_fk" FOREIGN KEY ("ProductId") REFERENCES "products"."Products"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'GoodsReceipts_PurchaseOrderId_PurchaseOrders_Id_fk' AND conrelid = '"purchases"."GoodsReceipts"'::regclass) THEN
		ALTER TABLE "purchases"."GoodsReceipts" ADD CONSTRAINT "GoodsReceipts_PurchaseOrderId_PurchaseOrders_Id_fk" FOREIGN KEY ("PurchaseOrderId") REFERENCES "purchases"."PurchaseOrders"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PurchaseOrderItems_PurchaseOrderId_PurchaseOrders_Id_fk' AND conrelid = '"purchases"."PurchaseOrderItems"'::regclass) THEN
		ALTER TABLE "purchases"."PurchaseOrderItems" ADD CONSTRAINT "PurchaseOrderItems_PurchaseOrderId_PurchaseOrders_Id_fk" FOREIGN KEY ("PurchaseOrderId") REFERENCES "purchases"."PurchaseOrders"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PurchaseOrderItems_ProductId_Products_Id_fk' AND conrelid = '"purchases"."PurchaseOrderItems"'::regclass) THEN
		ALTER TABLE "purchases"."PurchaseOrderItems" ADD CONSTRAINT "PurchaseOrderItems_ProductId_Products_Id_fk" FOREIGN KEY ("ProductId") REFERENCES "products"."Products"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PurchaseOrders_BusinessId_Businesses_Id_fk' AND conrelid = '"purchases"."PurchaseOrders"'::regclass) THEN
		ALTER TABLE "purchases"."PurchaseOrders" ADD CONSTRAINT "PurchaseOrders_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PurchaseOrders_StoreId_Stores_Id_fk' AND conrelid = '"purchases"."PurchaseOrders"'::regclass) THEN
		ALTER TABLE "purchases"."PurchaseOrders" ADD CONSTRAINT "PurchaseOrders_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PurchaseOrders_SupplierId_Suppliers_Id_fk' AND conrelid = '"purchases"."PurchaseOrders"'::regclass) THEN
		ALTER TABLE "purchases"."PurchaseOrders" ADD CONSTRAINT "PurchaseOrders_SupplierId_Suppliers_Id_fk" FOREIGN KEY ("SupplierId") REFERENCES "suppliers"."Suppliers"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'CheckoutIdempotency_TransactionId_Transactions_Id_fk' AND conrelid = '"transactions"."CheckoutIdempotency"'::regclass) THEN
		ALTER TABLE "transactions"."CheckoutIdempotency" ADD CONSTRAINT "CheckoutIdempotency_TransactionId_Transactions_Id_fk" FOREIGN KEY ("TransactionId") REFERENCES "transactions"."Transactions"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'TransactionItems_TransactionId_Transactions_Id_fk' AND conrelid = '"transactions"."TransactionItems"'::regclass) THEN
		ALTER TABLE "transactions"."TransactionItems" ADD CONSTRAINT "TransactionItems_TransactionId_Transactions_Id_fk" FOREIGN KEY ("TransactionId") REFERENCES "transactions"."Transactions"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'TransactionItems_ProductId_Products_Id_fk' AND conrelid = '"transactions"."TransactionItems"'::regclass) THEN
		ALTER TABLE "transactions"."TransactionItems" ADD CONSTRAINT "TransactionItems_ProductId_Products_Id_fk" FOREIGN KEY ("ProductId") REFERENCES "products"."Products"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'TransactionItems_ProductVariantId_ProductVariants_Id_fk' AND conrelid = '"transactions"."TransactionItems"'::regclass) THEN
		ALTER TABLE "transactions"."TransactionItems" ADD CONSTRAINT "TransactionItems_ProductVariantId_ProductVariants_Id_fk" FOREIGN KEY ("ProductVariantId") REFERENCES "products"."ProductVariants"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Transactions_BusinessId_Businesses_Id_fk' AND conrelid = '"transactions"."Transactions"'::regclass) THEN
		ALTER TABLE "transactions"."Transactions" ADD CONSTRAINT "Transactions_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Transactions_StoreId_Stores_Id_fk' AND conrelid = '"transactions"."Transactions"'::regclass) THEN
		ALTER TABLE "transactions"."Transactions" ADD CONSTRAINT "Transactions_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Transactions_StaffId_Staff_Id_fk' AND conrelid = '"transactions"."Transactions"'::regclass) THEN
		ALTER TABLE "transactions"."Transactions" ADD CONSTRAINT "Transactions_StaffId_Staff_Id_fk" FOREIGN KEY ("StaffId") REFERENCES "staff"."Staff"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Transactions_CustomerId_Customers_Id_fk' AND conrelid = '"transactions"."Transactions"'::regclass) THEN
		ALTER TABLE "transactions"."Transactions" ADD CONSTRAINT "Transactions_CustomerId_Customers_Id_fk" FOREIGN KEY ("CustomerId") REFERENCES "customers"."Customers"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Transactions_PaymentMethod_PaymentMethods_Code_fk' AND conrelid = '"transactions"."Transactions"'::regclass) THEN
		ALTER TABLE "transactions"."Transactions" ADD CONSTRAINT "Transactions_PaymentMethod_PaymentMethods_Code_fk" FOREIGN KEY ("PaymentMethod") REFERENCES "lookups"."PaymentMethods"("Code") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Transactions_TaxRateId_TaxRates_Id_fk' AND conrelid = '"transactions"."Transactions"'::regclass) THEN
		ALTER TABLE "transactions"."Transactions" ADD CONSTRAINT "Transactions_TaxRateId_TaxRates_Id_fk" FOREIGN KEY ("TaxRateId") REFERENCES "lookups"."TaxRates"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Payments_TransactionId_Transactions_Id_fk' AND conrelid = '"payments"."Payments"'::regclass) THEN
		ALTER TABLE "payments"."Payments" ADD CONSTRAINT "Payments_TransactionId_Transactions_Id_fk" FOREIGN KEY ("TransactionId") REFERENCES "transactions"."Transactions"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Payments_PaymentMethod_PaymentMethods_Code_fk' AND conrelid = '"payments"."Payments"'::regclass) THEN
		ALTER TABLE "payments"."Payments" ADD CONSTRAINT "Payments_PaymentMethod_PaymentMethods_Code_fk" FOREIGN KEY ("PaymentMethod") REFERENCES "lookups"."PaymentMethods"("Code") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'TransactionDiscounts_TransactionId_Transactions_Id_fk' AND conrelid = '"payments"."TransactionDiscounts"'::regclass) THEN
		ALTER TABLE "payments"."TransactionDiscounts" ADD CONSTRAINT "TransactionDiscounts_TransactionId_Transactions_Id_fk" FOREIGN KEY ("TransactionId") REFERENCES "transactions"."Transactions"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'TransactionDiscounts_DiscountId_Discounts_Id_fk' AND conrelid = '"payments"."TransactionDiscounts"'::regclass) THEN
		ALTER TABLE "payments"."TransactionDiscounts" ADD CONSTRAINT "TransactionDiscounts_DiscountId_Discounts_Id_fk" FOREIGN KEY ("DiscountId") REFERENCES "lookups"."Discounts"("Id") ON DELETE set null ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'TransactionRefundItems_RefundId_TransactionRefunds_Id_fk' AND conrelid = '"payments"."TransactionRefundItems"'::regclass) THEN
		ALTER TABLE "payments"."TransactionRefundItems" ADD CONSTRAINT "TransactionRefundItems_RefundId_TransactionRefunds_Id_fk" FOREIGN KEY ("RefundId") REFERENCES "payments"."TransactionRefunds"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'TransactionRefundItems_TransactionItemId_TransactionItems_Id_fk' AND conrelid = '"payments"."TransactionRefundItems"'::regclass) THEN
		ALTER TABLE "payments"."TransactionRefundItems" ADD CONSTRAINT "TransactionRefundItems_TransactionItemId_TransactionItems_Id_fk" FOREIGN KEY ("TransactionItemId") REFERENCES "transactions"."TransactionItems"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'TransactionRefundItems_ProductId_Products_Id_fk' AND conrelid = '"payments"."TransactionRefundItems"'::regclass) THEN
		ALTER TABLE "payments"."TransactionRefundItems" ADD CONSTRAINT "TransactionRefundItems_ProductId_Products_Id_fk" FOREIGN KEY ("ProductId") REFERENCES "products"."Products"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'TransactionRefunds_TransactionId_Transactions_Id_fk' AND conrelid = '"payments"."TransactionRefunds"'::regclass) THEN
		ALTER TABLE "payments"."TransactionRefunds" ADD CONSTRAINT "TransactionRefunds_TransactionId_Transactions_Id_fk" FOREIGN KEY ("TransactionId") REFERENCES "transactions"."Transactions"("Id") ON DELETE restrict ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'BusinessSettings_BusinessId_Businesses_Id_fk' AND conrelid = '"settings"."BusinessSettings"'::regclass) THEN
		ALTER TABLE "settings"."BusinessSettings" ADD CONSTRAINT "BusinessSettings_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ReceiptSettings_BusinessId_Businesses_Id_fk' AND conrelid = '"settings"."ReceiptSettings"'::regclass) THEN
		ALTER TABLE "settings"."ReceiptSettings" ADD CONSTRAINT "ReceiptSettings_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ReceiptSettings_StoreId_Stores_Id_fk' AND conrelid = '"settings"."ReceiptSettings"'::regclass) THEN
		ALTER TABLE "settings"."ReceiptSettings" ADD CONSTRAINT "ReceiptSettings_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'StoreSettings_BusinessId_Businesses_Id_fk' AND conrelid = '"settings"."StoreSettings"'::regclass) THEN
		ALTER TABLE "settings"."StoreSettings" ADD CONSTRAINT "StoreSettings_BusinessId_Businesses_Id_fk" FOREIGN KEY ("BusinessId") REFERENCES "core"."Businesses"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
DO $$ BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'StoreSettings_StoreId_Stores_Id_fk' AND conrelid = '"settings"."StoreSettings"'::regclass) THEN
		ALTER TABLE "settings"."StoreSettings" ADD CONSTRAINT "StoreSettings_StoreId_Stores_Id_fk" FOREIGN KEY ("StoreId") REFERENCES "core"."Stores"("Id") ON DELETE cascade ON UPDATE no action;
	END IF;
END $$;--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "AuditLogs_BusinessId_idx" ON "audit"."AuditLogs" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "AuditLogs_UserId_idx" ON "audit"."AuditLogs" USING btree ("UserId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "AuditLogs_EntityType_EntityId_idx" ON "audit"."AuditLogs" USING btree ("EntityType","EntityId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "AuditLogs_CreatedAt_idx" ON "audit"."AuditLogs" USING btree ("CreatedAt");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "FileAttachments_BusinessId_idx" ON "audit"."FileAttachments" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "FileAttachments_EntityType_EntityId_idx" ON "audit"."FileAttachments" USING btree ("EntityType","EntityId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "FileAttachments_StorageKey_idx" ON "audit"."FileAttachments" USING btree ("StorageKey");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Notifications_BusinessId_idx" ON "audit"."Notifications" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Notifications_UserId_idx" ON "audit"."Notifications" USING btree ("UserId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Notifications_ReadAt_idx" ON "audit"."Notifications" USING btree ("ReadAt");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Notifications_CreatedAt_idx" ON "audit"."Notifications" USING btree ("CreatedAt");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "BusinessMembers_BusinessId_idx" ON "core"."BusinessMembers" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "BusinessMembers_UserId_idx" ON "core"."BusinessMembers" USING btree ("UserId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "BusinessMembers_StoreId_idx" ON "core"."BusinessMembers" USING btree ("StoreId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Businesses_Status_idx" ON "core"."Businesses" USING btree ("Status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Permissions_Module_idx" ON "core"."Permissions" USING btree ("Module");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "RolePermissions_RoleCode_idx" ON "core"."RolePermissions" USING btree ("RoleCode");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "RolePermissions_PermissionCode_idx" ON "core"."RolePermissions" USING btree ("PermissionCode");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Roles_Rank_idx" ON "core"."Roles" USING btree ("Rank");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Stores_BusinessId_idx" ON "core"."Stores" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Stores_IsActive_idx" ON "core"."Stores" USING btree ("IsActive");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "UserProfiles_Role_idx" ON "core"."UserProfiles" USING btree ("Role");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "UserProfiles_Email_idx" ON "core"."UserProfiles" USING btree ("Email");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CustomerAddresses_CustomerId_idx" ON "customers"."CustomerAddresses" USING btree ("CustomerId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CustomerAddresses_IsPrimary_idx" ON "customers"."CustomerAddresses" USING btree ("IsPrimary");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Customers_BusinessId_idx" ON "customers"."Customers" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Customers_Phone_idx" ON "customers"."Customers" USING btree ("Phone");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Customers_Email_idx" ON "customers"."Customers" USING btree ("Email");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Customers_Name_idx" ON "customers"."Customers" USING btree ("Name");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Categories_BusinessId_idx" ON "products"."Categories" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Categories_ParentCategoryId_idx" ON "products"."Categories" USING btree ("ParentCategoryId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Categories_Name_idx" ON "products"."Categories" USING btree ("Name");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Categories_Status_idx" ON "products"."Categories" USING btree ("Status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "ProductBarcodes_ProductId_idx" ON "products"."ProductBarcodes" USING btree ("ProductId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "ProductPrices_ProductId_idx" ON "products"."ProductPrices" USING btree ("ProductId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "ProductPrices_StoreId_idx" ON "products"."ProductPrices" USING btree ("StoreId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "ProductPrices_PriceType_idx" ON "products"."ProductPrices" USING btree ("PriceType");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "ProductUnits_ProductId_idx" ON "products"."ProductUnits" USING btree ("ProductId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "ProductVariants_ProductId_idx" ON "products"."ProductVariants" USING btree ("ProductId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "ProductVariants_Barcode_idx" ON "products"."ProductVariants" USING btree ("Barcode");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Products_BusinessId_idx" ON "products"."Products" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Products_CategoryId_idx" ON "products"."Products" USING btree ("CategoryId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Products_Barcode_idx" ON "products"."Products" USING btree ("Barcode");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Products_Name_idx" ON "products"."Products" USING btree ("Name");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Products_Status_idx" ON "products"."Products" USING btree ("Status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Inventory_BusinessId_idx" ON "inventory"."Inventory" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Inventory_StoreId_idx" ON "inventory"."Inventory" USING btree ("StoreId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Inventory_ProductId_idx" ON "inventory"."Inventory" USING btree ("ProductId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "StockAdjustments_BusinessId_idx" ON "inventory"."StockAdjustments" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "StockAdjustments_StoreId_idx" ON "inventory"."StockAdjustments" USING btree ("StoreId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "StockAdjustments_ProductId_idx" ON "inventory"."StockAdjustments" USING btree ("ProductId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "StockAdjustments_CreatedAt_idx" ON "inventory"."StockAdjustments" USING btree ("CreatedAt");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "StockMovements_BusinessId_idx" ON "inventory"."StockMovements" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "StockMovements_StoreId_idx" ON "inventory"."StockMovements" USING btree ("StoreId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "StockMovements_ProductId_idx" ON "inventory"."StockMovements" USING btree ("ProductId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "StockMovements_CreatedAt_idx" ON "inventory"."StockMovements" USING btree ("CreatedAt");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "StockMovements_ReferenceId_idx" ON "inventory"."StockMovements" USING btree ("ReferenceId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Discounts_BusinessId_idx" ON "lookups"."Discounts" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Discounts_IsActive_idx" ON "lookups"."Discounts" USING btree ("IsActive");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "PaymentMethods_IsActive_idx" ON "lookups"."PaymentMethods" USING btree ("IsActive");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "PaymentMethods_SortOrder_idx" ON "lookups"."PaymentMethods" USING btree ("SortOrder");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "TaxRates_BusinessId_idx" ON "lookups"."TaxRates" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "TaxRates_IsDefault_idx" ON "lookups"."TaxRates" USING btree ("IsDefault");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CashMovements_SessionId_idx" ON "staff"."CashMovements" USING btree ("SessionId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CashMovements_StaffId_idx" ON "staff"."CashMovements" USING btree ("StaffId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CashMovements_CreatedAt_idx" ON "staff"."CashMovements" USING btree ("CreatedAt");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CashRegisterSessions_CashRegisterId_idx" ON "staff"."CashRegisterSessions" USING btree ("CashRegisterId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CashRegisterSessions_StoreId_idx" ON "staff"."CashRegisterSessions" USING btree ("StoreId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CashRegisterSessions_OpenedByStaffId_idx" ON "staff"."CashRegisterSessions" USING btree ("OpenedByStaffId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CashRegisterSessions_Status_idx" ON "staff"."CashRegisterSessions" USING btree ("Status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CashRegisters_BusinessId_idx" ON "staff"."CashRegisters" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CashRegisters_StoreId_idx" ON "staff"."CashRegisters" USING btree ("StoreId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Shifts_BusinessId_idx" ON "staff"."Shifts" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Shifts_StoreId_idx" ON "staff"."Shifts" USING btree ("StoreId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Shifts_StaffId_idx" ON "staff"."Shifts" USING btree ("StaffId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Shifts_StartTime_idx" ON "staff"."Shifts" USING btree ("StartTime");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Staff_BusinessId_idx" ON "staff"."Staff" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Staff_StoreId_idx" ON "staff"."Staff" USING btree ("StoreId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Staff_UserId_idx" ON "staff"."Staff" USING btree ("UserId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Staff_Role_idx" ON "staff"."Staff" USING btree ("Role");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Staff_Status_idx" ON "staff"."Staff" USING btree ("Status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Suppliers_BusinessId_idx" ON "suppliers"."Suppliers" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Suppliers_Name_idx" ON "suppliers"."Suppliers" USING btree ("Name");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Suppliers_Status_idx" ON "suppliers"."Suppliers" USING btree ("Status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "GoodsReceiptItems_GoodsReceiptId_idx" ON "purchases"."GoodsReceiptItems" USING btree ("GoodsReceiptId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "GoodsReceiptItems_PurchaseOrderItemId_idx" ON "purchases"."GoodsReceiptItems" USING btree ("PurchaseOrderItemId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "GoodsReceiptItems_ProductId_idx" ON "purchases"."GoodsReceiptItems" USING btree ("ProductId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "GoodsReceipts_PurchaseOrderId_idx" ON "purchases"."GoodsReceipts" USING btree ("PurchaseOrderId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "GoodsReceipts_ReceivedAt_idx" ON "purchases"."GoodsReceipts" USING btree ("ReceivedAt");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "PurchaseOrderItems_PurchaseOrderId_idx" ON "purchases"."PurchaseOrderItems" USING btree ("PurchaseOrderId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "PurchaseOrderItems_ProductId_idx" ON "purchases"."PurchaseOrderItems" USING btree ("ProductId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "PurchaseOrders_BusinessId_idx" ON "purchases"."PurchaseOrders" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "PurchaseOrders_StoreId_idx" ON "purchases"."PurchaseOrders" USING btree ("StoreId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "PurchaseOrders_SupplierId_idx" ON "purchases"."PurchaseOrders" USING btree ("SupplierId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "PurchaseOrders_Status_idx" ON "purchases"."PurchaseOrders" USING btree ("Status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "PurchaseOrders_OrderDate_idx" ON "purchases"."PurchaseOrders" USING btree ("OrderDate");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CheckoutIdempotency_TransactionId_idx" ON "transactions"."CheckoutIdempotency" USING btree ("TransactionId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "CheckoutIdempotency_ExpiresAt_idx" ON "transactions"."CheckoutIdempotency" USING btree ("ExpiresAt");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "TransactionItems_TransactionId_idx" ON "transactions"."TransactionItems" USING btree ("TransactionId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "TransactionItems_ProductId_idx" ON "transactions"."TransactionItems" USING btree ("ProductId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "TransactionItems_ProductVariantId_idx" ON "transactions"."TransactionItems" USING btree ("ProductVariantId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Transactions_BusinessId_idx" ON "transactions"."Transactions" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Transactions_StoreId_idx" ON "transactions"."Transactions" USING btree ("StoreId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Transactions_CustomerId_idx" ON "transactions"."Transactions" USING btree ("CustomerId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Transactions_StaffId_idx" ON "transactions"."Transactions" USING btree ("StaffId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Transactions_CreatedAt_idx" ON "transactions"."Transactions" USING btree ("CreatedAt");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Transactions_Status_idx" ON "transactions"."Transactions" USING btree ("Status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Transactions_PaymentMethod_idx" ON "transactions"."Transactions" USING btree ("PaymentMethod");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Payments_TransactionId_idx" ON "payments"."Payments" USING btree ("TransactionId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Payments_PaymentMethod_idx" ON "payments"."Payments" USING btree ("PaymentMethod");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "Payments_PaidAt_idx" ON "payments"."Payments" USING btree ("PaidAt");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "TransactionDiscounts_TransactionId_idx" ON "payments"."TransactionDiscounts" USING btree ("TransactionId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "TransactionDiscounts_DiscountId_idx" ON "payments"."TransactionDiscounts" USING btree ("DiscountId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "TransactionRefundItems_RefundId_idx" ON "payments"."TransactionRefundItems" USING btree ("RefundId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "TransactionRefundItems_TransactionItemId_idx" ON "payments"."TransactionRefundItems" USING btree ("TransactionItemId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "TransactionRefundItems_ProductId_idx" ON "payments"."TransactionRefundItems" USING btree ("ProductId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "TransactionRefunds_TransactionId_idx" ON "payments"."TransactionRefunds" USING btree ("TransactionId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "TransactionRefunds_Status_idx" ON "payments"."TransactionRefunds" USING btree ("Status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "BusinessSettings_BusinessId_idx" ON "settings"."BusinessSettings" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "ReceiptSettings_BusinessId_idx" ON "settings"."ReceiptSettings" USING btree ("BusinessId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "ReceiptSettings_StoreId_idx" ON "settings"."ReceiptSettings" USING btree ("StoreId");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "StoreSettings_BusinessId_idx" ON "settings"."StoreSettings" USING btree ("BusinessId");