import { LayoutDashboard, Search, Package, FileText, Settings } from "lucide-react"

// Shared across every real app shell (Package Builder's page-scoped sidebar,
// and the (app) group's shared AppShell — T0016) so the destination list
// can't drift between them. Dashboard/Quotes are placeholder hrefs — those
// pages don't exist yet (T0043, and Quotes' real home is still TBD, so it
// points at Compatibility Checker for now as the closest real destination).
// Browse and Packages are the only genuinely real destinations today.
export const NAV_ITEMS = [
  { label: "Dashboard", href: "/", icon: <LayoutDashboard size={15} strokeWidth={1.7} /> },
  { label: "Browse", href: "/gear", icon: <Search size={15} strokeWidth={1.7} /> },
  { label: "Packages", href: "/package-builder", icon: <Package size={15} strokeWidth={1.7} /> },
  { label: "Quotes", href: "/compatibility-checker", icon: <FileText size={15} strokeWidth={1.7} /> },
]

export const SETTINGS_NAV_ITEM = { label: "Settings", icon: <Settings size={15} strokeWidth={1.7} /> }
