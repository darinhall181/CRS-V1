// www/src/app/api/waitlist/route.ts
import { NextResponse } from "next/server"
import { db } from "@/lib/db"
import { waitlistSignup } from "@/lib/db/schema"

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/

export async function POST(req: Request) {
  let body: unknown
  try {
    body = await req.json()
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 })
  }

  const email = String((body as { email?: string })?.email ?? "").trim().toLowerCase()
  if (!EMAIL.test(email) || email.length > 254) {
    return NextResponse.json({ error: "Enter a valid email address." }, { status: 400 })
  }

  await db
    .insert(waitlistSignup)
    .values({
      email,
      source: "landing",
      referrer: req.headers.get("referer") ?? null,
    })
    .onConflictDoNothing({ target: waitlistSignup.email })

  return NextResponse.json({ ok: true })
}
