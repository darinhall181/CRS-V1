import { Suspense } from "react"
import { AuthErrorContent } from "./auth-error-content"

// Public by design — this is exactly the page someone lands on when a
// sign-in attempt FAILED, so it can never require being signed in. Better
// Auth's own default (a generic unstyled page at /api/auth/error) is
// redirected here via auth.ts's onAPIError.errorURL, added 2026-08-10 after
// a real access_denied hit during Google OAuth testing.
//
// Split into a server page.tsx + client auth-error-content.tsx (rather than
// a single "use client" page) because AuthErrorContent's useSearchParams()
// needs an actual Suspense boundary above it during static prerendering —
// `export const dynamic = "force-dynamic"` on a fully-client page.tsx isn't
// reliably honored by Next 14's build (confirmed: still failed the build
// with just that). This split is the pattern Next.js's own docs recommend.
export default function AuthErrorPage() {
  return (
    <Suspense fallback={null}>
      <AuthErrorContent />
    </Suspense>
  )
}
