import { LayoutDashboard, Search, Package, FileText, Users, Settings } from "lucide-react"

// Shared across every real app shell (Package Builder's page-scoped sidebar,
// and the (app) group's shared AppShell — T0016) so the destination list
// can't drift between them.
//
// `href: null` marks a placeholder — deliberately inert (no click handler
// wired by consumers below) rather than pointing at "/", since navigating a
// signed-in user to the public marketing/waitlist page reads as a bug, not
// a coming-soon state. Only Browse and Packages are real destinations today:
//   Dashboard → T0043 (www/(app)/dashboard/)
//   CRM       → T0041 (www/(app)/crm/)
//   Quotes    → no task yet; previous placeholder (Compatibility Checker)
//               was scrapped 2026-08-09, see T0048 for revisiting that page
//
// 2026-08-09 — "History" removed from this list entirely (was here as a
// placeholder, T0016's original 6-item shape). Decided it doesn't belong as
// a global destination: history is almost always about one specific
// package, not a cross-app feed. It now lives as a tab on Package Builder
// itself instead — see package-builder-client.tsx's HistoryPanel, backed by
// the package_events table (T0025).
export const NAV_ITEMS: { label: string; href: string | null; icon: React.ReactNode }[] = [
  { label: "Dashboard", href: null, icon: <LayoutDashboard size={15} strokeWidth={1.7} /> },
  { label: "Browse", href: "/browse", icon: <Search size={15} strokeWidth={1.7} /> },
  { label: "Packages", href: "/package-builder", icon: <Package size={15} strokeWidth={1.7} /> },
  { label: "Quotes", href: null, icon: <FileText size={15} strokeWidth={1.7} /> },
  { label: "CRM", href: null, icon: <Users size={15} strokeWidth={1.7} /> },
]

export const SETTINGS_NAV_ITEM = { label: "Settings", icon: <Settings size={15} strokeWidth={1.7} /> }
