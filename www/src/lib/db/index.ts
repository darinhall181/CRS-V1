import { drizzle } from "drizzle-orm/postgres-js"
import postgres from "postgres"
import * as schema from "./schema"

// Singleton pattern — reuse the connection across hot reloads in dev.
const globalForDb = globalThis as unknown as { _pgClient: postgres.Sql }

const dbUrl = process.env.SUPABASE_DB_URL!

const isLocal = dbUrl?.includes("127.0.0.1") || dbUrl?.includes("localhost")

const client =
  globalForDb._pgClient ??
  postgres(dbUrl, {
    ssl: isLocal ? false : "require",
    max: 10,
  })

if (process.env.NODE_ENV !== "production") {
  globalForDb._pgClient = client
}

export const db = drizzle(client, { schema })
