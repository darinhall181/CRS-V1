import { redirect } from "next/navigation"
import { getSession } from "@/lib/session"
import { getOnboardingState } from "@/lib/db/queries"
import { OnboardingClient } from "./onboarding-client"

export const metadata = {
  title: "Set up your workspace — Altoscope",
}

// T0019 — steps 1–5 of Onboarding.dc.html (step 0 is the login page, T0018).
// Always re-enters at step 1 (matches the prototype's SPA reset-on-remount
// behavior) but every field is pre-filled from whatever's already saved —
// see queries.ts's getOnboardingState — so a mid-flow abandon-and-return
// doesn't lose step 1–2 answers even though the step counter itself resets.
export default async function OnboardingPage() {
  const session = await getSession()
  if (!session) redirect("/login")

  const state = await getOnboardingState(session.user.id)
  // Already done — someone navigating here directly after finishing (the
  // redirect gate on every other protected page would've sent them
  // elsewhere already, so this is only reachable by typing the URL).
  if (state?.onboardingCompletedAt) redirect("/package-builder")

  return <OnboardingClient initialState={state} userName={session.user.name} />
}
