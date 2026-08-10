import { redirect } from "next/navigation"
import { getViewerContext } from "@/lib/viewer-context"
import { getProduction, getCompany } from "@/lib/db/queries"
import { AppShell } from "./app-shell"

// Same demo-fallback production as Package Builder — see that page.tsx for
// the full rationale (single-tenant demo state, real production
// selection/routing is separate, bigger work).
const DEMO_PRODUCTION_ID = "3bd8e7c3-d0a0-4382-960c-c104c472a6ee"

export default async function AppLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const viewer = await getViewerContext()
  // T0019 — every real page behind this shell requires onboarding to be
  // done first. A signed-out viewer is null here (middleware already
  // redirected to /login for the routes this layout covers) — only a real,
  // signed-in-but-incomplete viewer gets bounced.
  if (viewer && !viewer.onboardingCompletedAt) redirect("/signup")
  const productionId = viewer?.productionId ?? DEMO_PRODUCTION_ID
  const production = await getProduction(productionId)
  const company = production ? await getCompany(production.companyId) : null

  return (
    <AppShell userName={viewer?.user.name ?? "Guest"} companyName={company?.name ?? null}>
      {children}
    </AppShell>
  )
}
