import { NextResponse, type NextRequest } from "next/server"
import { getSessionCookie } from "better-auth/cookies"

export function middleware(request: NextRequest) {
  const sessionCookie = getSessionCookie(request)

  if (!sessionCookie) {
    // /signup (T0019's onboarding wizard) is the one protected route that
    // implies "I want to create an account" rather than "log back in" —
    // send it to /register instead of /login.
    const isSignupIntent = request.nextUrl.pathname === "/signup"
    const authUrl = new URL(isSignupIntent ? "/register" : "/login", request.url)
    authUrl.searchParams.set("next", request.nextUrl.pathname)
    return NextResponse.redirect(authUrl)
  }

  return NextResponse.next()
}

export const config = {
  matcher: ["/package-builder", "/browse", "/signup", "/dashboard", "/profile"],
}
