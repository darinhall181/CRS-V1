import { LayoutDashboard, Search, Package, FileText, History as HistoryIcon, Users, Settings } from "lucide-react"

// Shared across every real app shell (Package Builder's page-scoped sidebar,
// and the (app) group's shared AppShell — T0016) so the destination list
// can't drift between them. 2026-08-09: expanded to the full 6-item shape
// (+ Settings below a divider) per Darin's direction — a shell for pages
// that don't exist yet, not a promise they're all equally close.
//
// `href: null` marks a placeholder — deliberately inert (no click handler
// wired by consumers below) rather than pointing at "/", since navigating a
// signed-in user to the public marketing/waitlist page reads as a bug, not
// a coming-soon state. Only Browse and Packages are real destinations today:
//   Dashboard → T0043 (www/(app)/dashboard/)
//   History   → T0042 (www/(app)/history/)
//   CRM       → T0041 (www/(app)/crm/)
//   Quotes    → no task yet; previous placeholder (Compatibility Checker)
//               was scrapped 2026-08-09, see T0048 for revisiting that page
export const NAV_ITEMS: { label: string; href: string | null; icon: React.ReactNode }[] = [
  { label: "Dashboard", href: null, icon: <LayoutDashboard size={15} strokeWidth={1.7} /> },
  { label: "Browse", href: "/gear", icon: <Search size={15} strokeWidth={1.7} /> },
  { label: "Packages", href: "/package-builder", icon: <Package size={15} strokeWidth={1.7} /> },
  { label: "Quotes", href: null, icon: <FileText size={15} strokeWidth={1.7} /> },
  { label: "History", href: null, icon: <HistoryIcon size={15} strokeWidth={1.7} /> },
  { label: "CRM", href: null, icon: <Users size={15} strokeWidth={1.7} /> },
]

export const SETTINGS_NAV_ITEM = { label: "Settings", icon: <Settings size={15} strokeWidth={1.7} /> }
