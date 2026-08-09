"use client"

import { useState } from "react"
import { useRouter, usePathname } from "next/navigation"
import { Building2 } from "lucide-react"
import { SidebarNav, TopBar } from "@/components/elevation"
import { NAV_ITEMS, SETTINGS_NAV_ITEM } from "@/components/nav/nav-items"
import { AltoscopeLogo } from "@/components/nav/logo"
import { AccountMenu } from "@/components/nav/account-menu"

// T0016 — shared shell for the (app) route group (Browse today; future
// Dashboard/Quotes/History/CRM land here too — see nav-items.tsx), replacing
// the old light shadcn <Navbar/>. Composed from the same Elevation Kit
// primitives and nav-items.tsx config as Package Builder's page-scoped
// shell, so the two read as one product rather than two — full-width
// TopBar above a flush, collapsible sidebar (Navigation Options "1a",
// leaning-hybrid direction per T0016's notes).
//
// Package Builder deliberately keeps its own shell (package-builder-sidebar/
// -topbar.tsx) rather than moving into this one — the width Package
// Builder's three-pane layout needs is exactly the tradeoff T0016's own
// notes flag against a shared 1a sidebar ("noticeable on the three-pane
// package builder"). Unifying that is a separate, bigger call — not
// something to fold in here as a side effect.
export function AppShell({
  children,
  userName,
  companyName,
}: {
  children: React.ReactNode
  userName: string
  companyName: string | null
}) {
  const router = useRouter()
  const pathname = usePathname()
  const [collapsed, setCollapsed] = useState(false)

  return (
    <div className="flex h-screen flex-col bg-[var(--bg-base)] text-[var(--text-primary)]">
      <TopBar
        logo={<AltoscopeLogo />}
        wordmark="Altoscope"
        searchPlaceholder="Search gear, packages, rental houses"
        userMenu={<AccountMenu userName={userName} />}
      />

      <div className="flex flex-1 min-h-0">
        <SidebarNav
          flush
          width={180}
          items={NAV_ITEMS.map((item) => ({
            label: item.label,
            icon: item.icon,
            active: item.href !== null && pathname === item.href,
            onClick: item.href ? () => router.push(item.href!) : undefined,
          }))}
          secondaryItems={[SETTINGS_NAV_ITEM]}
          workspaces={
            companyName
              ? [{ name: companyName, icon: <Building2 size={16} strokeWidth={1.7} />, active: true }]
              : undefined
          }
          workspaceLabel="Production studio"
          collapsed={collapsed}
          onToggleCollapsed={() => setCollapsed((v) => !v)}
        />

        <div className="flex-1 overflow-auto">{children}</div>
      </div>
    </div>
  )
}
