import { redirect } from "next/navigation"
import { AuthForm } from "@/components/auth/auth-form"
import { getSession } from "@/lib/session"
import { getOnboardingCompletedAt } from "@/lib/db/queries"

export const metadata = {
  title: "Create an account — Altoscope",
}

// Already-signed-in users should never see the signup form — send them on to
// wherever they were headed. If onboarding isn't finished yet, go straight
// there instead of /dashboard, since (app)/layout.tsx's gate would just
// bounce them to /onboarding anyway.
export default async function SignupPage({
  searchParams,
}: {
  searchParams: { next?: string }
}) {
  const session = await getSession()
  if (session) {
    const onboardingCompletedAt = await getOnboardingCompletedAt(session.user.id)
    redirect(onboardingCompletedAt ? searchParams.next || "/dashboard" : "/onboarding")
  }

  return <AuthForm mode="sign-up" />
}
