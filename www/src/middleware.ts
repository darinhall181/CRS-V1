import { NextResponse, type NextRequest } from "next/server"

// Login-gating is TEMPORARILY DISABLED (task #18, decided 2026-08-05): no
// page differentiates by role yet and all data is synthetic demo data, so
// the gate has no real security payoff right now — only friction during
// active UI iteration. Re-enable once building real role-gated views
// (task #19/#20) — see git history on this file for the working version:
// getSessionCookie(request) from "better-auth/cookies", redirect to /login
// with a `next` param when absent, matcher on /package-builder, /gear,
// /compatibility-checker.
export function middleware(_request: NextRequest) {
  return NextResponse.next()
}
