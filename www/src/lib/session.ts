import { headers } from "next/headers"
import { auth } from "./auth"

// Server-only — usable from Server Components and Server Actions ("use server"
// files), both of which have access to the incoming request's headers via
// next/headers. Not usable from Route Handlers with a custom Request object;
// pass that request's headers to auth.api.getSession directly there instead.
export async function getSession() {
  return auth.api.getSession({ headers: await headers() })
}
