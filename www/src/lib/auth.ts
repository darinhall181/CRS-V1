import { betterAuth } from "better-auth"
import { drizzleAdapter } from "better-auth/adapters/drizzle"
import { db } from "./db"
import { users, session, account, verification } from "./db/schema"

export const auth = betterAuth({
  database: drizzleAdapter(db, {
    provider: "pg",
    schema: { user: users, session, account, verification },
  }),
  // .env.local sets BETTER_AUTH_URL explicitly (localhost:3004) for local
  // dev — unaffected by anything below. On Vercel, VERCEL_URL is injected
  // automatically for every deployment (preview and production alike), so
  // this falls back to it instead of needing a fixed value that would only
  // be correct for one specific preview URL. Leave BETTER_AUTH_URL unset in
  // Vercel's dashboard env vars — this makes that unnecessary. Only set it
  // there if you want a stable custom production domain instead of the
  // auto-assigned *.vercel.app one.
  baseURL: process.env.BETTER_AUTH_URL || (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : undefined),
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
