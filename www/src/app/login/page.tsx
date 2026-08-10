import { redirect } from "next/navigation"
import { AuthForm } from "@/components/auth/auth-form"
import { getSession } from "@/lib/session"
import { getOnboardingCompletedAt } from "@/lib/db/queries"

export const metadata = {
  title: "Log in — Altoscope",
}

// Forces this route to render dynamically instead of being statically
// prerendered at build time — without it, `next build` fails: AuthForm (a
// client component) calls useSearchParams(), which Next.js requires a
// Suspense boundary for during static generation. This page is already
// inherently dynamic (getSession() reads cookies below), this just makes
// that explicit so the build doesn't try to prerender it as static first.
export const dynamic = "force-dynamic"

// Already-signed-in users should never see the login form — send them on to
// wherever they were headed. If onboarding isn't finished yet, go straight
// there instead of /dashboard, since (app)/layout.tsx's gate would just
// bounce them to /onboarding anyway.
export default async function LoginPage({
  searchParams,
}: {
  searchParams: { next?: string }
}) {
  const session = await getSession()
  if (session) {
    const onboardingCompletedAt = await getOnboardingCompletedAt(session.user.id)
    redirect(onboardingCompletedAt ? searchParams.next || "/dashboard" : "/onboarding")
  }

  return <AuthForm mode="sign-in" />
}
