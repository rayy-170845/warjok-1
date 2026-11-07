import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";

const connectionString = process.env.DATABASE_URL || "postgres://dummy:dummy@localhost:5432/dummy";

const poolConnectionString =
  process.env.WARJOK_TEST_DATABASE_URL || connectionString;

/**
 * Drizzle selalu menuliskan nama schema secara eksplisit (mis.
 * `"core"."Users"`), jadi tidak perlu mengatur `search_path` di koneksi.
 * Ini juga menghindari batasan startup parameter pada koneksi pooled Neon.
 */
export const pool = new Pool({ connectionString: poolConnectionString });

export const db = drizzle(pool);
