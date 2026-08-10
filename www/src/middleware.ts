import { NextResponse, type NextRequest } from "next/server"
import { getSessionCookie } from "better-auth/cookies"

export function middleware(request: NextRequest) {
  const sessionCookie = getSessionCookie(request)

  if (!sessionCookie) {
    // /onboarding (T0019's wizard) is the one protected route that implies
    // "I want to create an account" rather than "log back in" — send it to
    // /signup instead of /login.
    const isSignupIntent = request.nextUrl.pathname === "/onboarding"
    const authUrl = new URL(isSignupIntent ? "/signup" : "/login", request.url)
    authUrl.searchParams.set("next", request.nextUrl.pathname)
    return NextResponse.redirect(authUrl)
  }

  return NextResponse.next()
}

export const config = {
  matcher: ["/package-builder", "/browse", "/onboarding", "/dashboard", "/profile"],
}
