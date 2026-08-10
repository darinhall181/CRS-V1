"use client"

import { useState } from "react"
import { useRouter, usePathname } from "next/navigation"
import { Building2, Plus } from "lucide-react"
import { SidebarNav } from "@/components/elevation"
import { NAV_ITEMS, SETTINGS_NAV_ITEM } from "@/components/nav/nav-items"

// Package Builder's left nav — Navigation Options "1a" wireframe restyled
// flush (Storefront handoff's borderless treatment, T0034/T0036 primitives).
// Width settled at 180px after a too-narrow 144px pass (2/3 of 216) made
// "Production Studio"/"Harpeth Valley Studios" wrap to 3 lines — long labels
// still wrap and grow their row's height rather than clip, just less often.
// Nav destinations here are the old top-center "Browse · Packages · Quote"
// tabs moved into the sidebar, and shared with (app)'s AppShell (T0016) via
// nav-items.tsx so the destination list can't drift between the two shells.
//
// "Add gear" history: started in the top action row, moved into the sidebar
// header slot 2026-08-08 (its own bright bg-interactive-default button,
// above Dashboard/Browse/etc.), moved again 2026-08-10 at Darin's request —
// he didn't like it living at the top, so it's now the first secondary item,
// directly above Settings under that same divider, styled like any other
// nav row instead of a standalone CTA button. Still opens the same
// left-side catalog drawer (Sheet); still page-specific, so it stays here
// rather than moving into a shared primitive.
//
// Logo/wordmark deliberately omitted here — they now live in
// PackageBuilderTopBar instead, so the brand mark stays a fixed size/position
// and isn't affected by this sidebar's collapse/width transitions.
export function PackageBuilderSidebar({
  companyName,
  onAddGear,
}: {
  companyName: string | null
  onAddGear: () => void
}) {
  const router = useRouter()
  const pathname = usePathname()
  const [collapsed, setCollapsed] = useState(false)

  return (
    <SidebarNav
      flush
      width={180}
      items={NAV_ITEMS.map((item) => ({
        label: item.label,
        icon: item.icon,
        active: item.href !== null && pathname === item.href,
        onClick: item.href ? () => router.push(item.href!) : undefined,
      }))}
      secondaryItems={[
        { label: "Add gear", icon: <Plus size={15} strokeWidth={1.7} />, onClick: onAddGear, outline: true },
        SETTINGS_NAV_ITEM,
      ]}
      workspaces={
        companyName
          ? [{ name: companyName, icon: <Building2 size={16} strokeWidth={1.7} />, active: true }]
          : undefined
      }
      workspaceLabel="Production studio"
      collapsed={collapsed}
      onToggleCollapsed={() => setCollapsed((v) => !v)}
    />
  )
}
