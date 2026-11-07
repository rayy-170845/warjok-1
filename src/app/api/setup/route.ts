import { eq, sql } from "drizzle-orm";
import { NextResponse } from "next/server";
import { z } from "zod";

import { getSession } from "@/lib/auth";
import { db } from "@/server/db";
import {
  businessMembers,
  businesses,
  businessSettings,
  DEFAULT_BUSINESS_ID,
  DEFAULT_STORE_ID,
  receiptSettings,
  stores,
  storeSettings,
  taxRates,
  userProfiles,
} from "@/server/db/schema";

const SetupSchema = z.object({
  businessName: z.string().trim().min(2).max(120),
  storeName: z.string().trim().min(2).max(120),
  address: z.string().trim().max(300).optional().default(""),
  phone: z.string().trim().max(32).optional().default(""),
  email: z
    .string()
    .trim()
    .email()
    .max(254)
    .optional()
    .or(z.literal(""))
    .default(""),
});

async function getSignedInUser() {
  const session = await getSession();
  return (session as any)?.user ?? (session as any)?.data?.user ?? null;
}

async function isOwner(userId: string) {
  const [profile] = await db
    .select({ role: userProfiles.role })
    .from(userProfiles)
    .where(eq(userProfiles.userId, userId))
    .limit(1);
  return profile?.role === "owner";
}

export async function GET() {
  const user = await getSignedInUser();
  if (!user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const [[business], [store]] = await Promise.all([
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
    ]);
    return NextResponse.json({
      setupRequired: !business || !store,
      canSetup: await isOwner(String(user.id)),
    });
  } catch (error) {
    console.error("Business setup status error:", error);
    return NextResponse.json(
      { error: "Status setup bisnis gagal dimuat." },
      { status: 500 }
    );
  }
}

export async function POST(request: Request) {
  const user = await getSignedInUser();
  if (!user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = String(user.id);
  try {
    if (!(await isOwner(userId))) {
      return NextResponse.json(
        { error: "Hanya pemilik Warjok yang dapat menyiapkan bisnis." },
        { status: 403 }
      );
    }

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return NextResponse.json(
        { error: "Format data setup tidak valid." },
        { status: 400 }
      );
    }

    const parsed = SetupSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Data setup tidak valid.", details: parsed.error.flatten() },
        { status: 400 }
      );
    }

    const values = parsed.data;
    const now = new Date();
    const result = await db.transaction(async (tx) => {
      await tx.execute(
        sql`select pg_advisory_xact_lock(hashtext('warjok-default-business-setup'))`
      );

      const [existingBusiness] = await tx
        .select({ id: businesses.id })
        .from(businesses)
        .where(eq(businesses.id, DEFAULT_BUSINESS_ID))
        .limit(1);
      const [existingStore] = await tx
        .select({ id: stores.id })
        .from(stores)
        .where(eq(stores.id, DEFAULT_STORE_ID))
        .limit(1);

      if (existingBusiness && existingStore) {
        return { alreadyConfigured: true };
      }

      const slug =
        values.businessName
          .normalize("NFKD")
          .replace(/[\u0300-\u036f]/g, "")
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, "-")
          .replace(/^-|-$/g, "") || "warjok";

      if (!existingBusiness) {
        await tx.insert(businesses).values({
          id: DEFAULT_BUSINESS_ID,
          name: values.businessName,
          slug,
          ownerUserId: userId,
          currency: "IDR",
          timezone: "Asia/Jakarta",
          status: "active",
          createdAt: now,
          updatedAt: now,
        });
      }

      if (!existingStore) {
        await tx.insert(stores).values({
          id: DEFAULT_STORE_ID,
          businessId: DEFAULT_BUSINESS_ID,
          name: values.storeName,
          code: "MAIN",
          address: values.address,
          phone: values.phone,
          email: values.email,
          timezone: "Asia/Jakarta",
          isActive: true,
          createdAt: now,
          updatedAt: now,
        });
      }

      await tx
        .insert(businessSettings)
        .values({
          id: "default",
          businessId: DEFAULT_BUSINESS_ID,
          businessName: values.businessName,
          address: values.address,
          phone: values.phone,
          email: values.email,
          currency: "IDR",
          timezone: "Asia/Jakarta",
          taxRate: "0",
          memberDiscountRate: "0",
          lowStockThreshold: 10,
          legacyReceiptFooter: "Terima kasih • Warjok",
          createdAt: now,
          updatedAt: now,
        })
        .onConflictDoNothing();

      await tx.insert(storeSettings).values({
        businessId: DEFAULT_BUSINESS_ID,
        storeId: DEFAULT_STORE_ID,
        lowStockThreshold: 10,
        taxRate: "0",
        createdAt: now,
        updatedAt: now,
      }).onConflictDoNothing();

      await tx.insert(receiptSettings).values({
        businessId: DEFAULT_BUSINESS_ID,
        storeId: DEFAULT_STORE_ID,
        header: values.businessName,
        footer: "Terima kasih • Warjok",
        showTax: true,
        showCashier: true,
        paperWidth: 58,
        createdAt: now,
        updatedAt: now,
      });

      await tx
        .insert(taxRates)
        .values({
          businessId: DEFAULT_BUSINESS_ID,
          name: "Default",
          rate: "0",
          isDefault: true,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        })
        .onConflictDoNothing();

      await tx.insert(businessMembers).values({
        businessId: DEFAULT_BUSINESS_ID,
        userId,
        role: "owner",
        storeId: DEFAULT_STORE_ID,
        status: "active",
        joinedAt: now,
        createdAt: now,
        updatedAt: now,
      }).onConflictDoNothing();

      return { alreadyConfigured: false };
    });

    if (result.alreadyConfigured) {
      return NextResponse.json(
        { error: "Setup bisnis sudah selesai." },
        { status: 409 }
      );
    }

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("Business setup error:", error);
    return NextResponse.json(
      { error: "Setup bisnis gagal disimpan. Silakan coba lagi." },
      { status: 500 }
    );
  }
}
