import { getViewerContext } from "@/lib/viewer-context"

export const metadata = {
  title: "Dashboard — Altoscope",
}

// Deliberate placeholder — the real dashboard (stat cards, active
// packages/requests, needs-attention rail, schedule, activity feed) is
// T0043 and isn't built yet. This exists only so /dashboard is a real
// destination: it's now the default post-sign-in landing page (see
// login/page.tsx and onboarding/page.tsx) and the left-nav "Dashboard"
// item's real href instead of a null placeholder.
export default async function DashboardPage() {
  const viewer = await getViewerContext()
  const name = viewer?.user.name?.split(" ")[0] ?? "there"

  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-2 px-8 text-center">
      <h1 className="m-0 text-2xl font-medium tracking-[-0.015em] text-[var(--text-primary)]">
        Good to see you, {name}
      </h1>
      <p className="m-0 text-sm text-[var(--text-secondary)]">
        The real dashboard is on its way — for now, jump into Browse or Packages from the sidebar.
      </p>
    </div>
  )
}
