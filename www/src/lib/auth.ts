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
  // Better Auth's built-in default (a generic un-styled HTML page at
  // /api/auth/error) fired for real 2026-08-10 when a Google OAuth attempt
  // came back access_denied — replaced with our own branded, public page.
  onAPIError: {
    errorURL: "/auth-error",
  },
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID as string,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET as string,
    },
  },
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
