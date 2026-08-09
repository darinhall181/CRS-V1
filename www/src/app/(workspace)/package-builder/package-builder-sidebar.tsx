"use client"

import { useState } from "react"
import { useRouter, usePathname } from "next/navigation"
import { Building2, Plus } from "lucide-react"
import { SidebarNav } from "@/components/elevation"
import { NAV_ITEMS, SETTINGS_NAV_ITEM } from "@/components/nav/nav-items"
import { cn } from "@/lib/utils"

// Package Builder's left nav — Navigation Options "1a" wireframe restyled
// flush (Storefront handoff's borderless treatment, T0034/T0036 primitives).
// Width settled at 180px after a too-narrow 144px pass (2/3 of 216) made
// "Production Studio"/"Harpeth Valley Studios" wrap to 3 lines — long labels
// still wrap and grow their row's height rather than clip, just less often.
// Nav destinations here are the old top-center "Browse · Packages · Quote"
// tabs moved into the sidebar, and shared with (app)'s AppShell (T0016) via
// nav-items.tsx so the destination list can't drift between the two shells.
//
// 2026-08-08 experiment: "Add gear" moved from the top action row into the
// sidebar header slot, at Darin's request, to see whether it reads better
// living next to the rest of the left-side navigation while still opening
// the same left-side catalog drawer (Sheet) — not yet confirmed as final.
// "Add gear" is specific to this page (opens the Package Builder catalog
// drawer) — not a global action, so it stays in this file's header slot
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
      header={
        <button
          type="button"
          title={collapsed ? "Add gear" : undefined}
          onClick={onAddGear}
          className={cn(
            "flex items-center gap-[7px] border-none bg-[var(--interactive-default)] text-white transition-colors hover:bg-[var(--interactive-hover)]",
            collapsed ? "h-[38px] w-[38px] justify-center rounded-full" : "h-[34px] w-full rounded-[8px] px-[10px]"
          )}
        >
          <Plus size={15} strokeWidth={2.2} />
          {!collapsed && <span className="text-[13px] font-medium">Add gear</span>}
        </button>
      }
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
  )
}
