import { getViewerContext } from "@/lib/viewer-context"

export const metadata = {
  title: "Profile — Altoscope",
}

// Deliberate placeholder, same pattern as (app)/dashboard/page.tsx — no
// task number yet. Exists so "Complete your profile" on the onboarding
// Ready screen (T0019) has a real destination instead of a stub notice.
// The real form (name, home market, experience level, referral source,
// rate/union/owner-kit/insurance — all captured by setOnboardingProfile /
// setOnboardingWorkingDetails in queries.ts) belongs here once built.
export default async function ProfilePage() {
  const viewer = await getViewerContext()
  const name = viewer?.user.name ?? "Guest"

  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-2 px-8 text-center">
      <h1 className="m-0 text-2xl font-medium tracking-[-0.015em] text-[var(--text-primary)]">
        {name}&apos;s profile
      </h1>
      <p className="m-0 text-sm text-[var(--text-secondary)]">
        Rates, credits, home market, and documents will live here — not built yet.
      </p>
    </div>
  )
}
