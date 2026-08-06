import { betterAuth } from "better-auth"
import { drizzleAdapter } from "better-auth/adapters/drizzle"
import { db } from "./db"
import { users, session, account, verification } from "./db/schema"

export const auth = betterAuth({
  database: drizzleAdapter(db, {
    provider: "pg",
    schema: { user: users, session, account, verification },
  }),
  baseURL: process.env.BETTER_AUTH_URL,
  secret: process.env.BETTER_AUTH_SECRET,
  emailAndPassword: { enabled: true },
  user: {
    additionalFields: {
      appRole: {
        type: "string",
        required: false,
        defaultValue: "user",
        // Server/admin-controlled only — never settable by the client on
        // sign-up or profile update, so a signup request can't self-grant a
        // privileged appRole.
        input: false,
      },
    },
  },
  databaseHooks: {
    user: {
      create: {
        before: async (user) => ({ data: { ...user, id: crypto.randomUUID() } }),
      },
    },
  },
})
