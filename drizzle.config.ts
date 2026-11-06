import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./src/server/db/schema/*",
  out: "./drizzle",
  dialect: "postgresql",
  schemaFilter: [
    "core",
    "products",
    "inventory",
    "customers",
    "staff",
    "suppliers",
    "purchases",
    "transactions",
    "payments",
    "lookups",
    "settings",
    "audit",
  ],
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
});
