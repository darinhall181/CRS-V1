import type { ReactNode } from "react"
import { PanelLeftClose, PanelLeftOpen } from "lucide-react"
import { cn } from "@/lib/utils"
import { FOCUS_RING } from "./shared"

export interface SidebarNavItem {
  label: string
  icon: ReactNode
  active?: boolean
  onClick?: () => void
}

export interface SidebarWorkspace {
  name: string
  icon: ReactNode
  active?: boolean
  onClick?: () => void
}

export interface SidebarNavProps {
  /**
   * Both optional — omit when the page's top bar owns the brand mark instead
   * (Package Builder's flush treatment latches logo/wordmark to the top bar
   * so it stays a fixed size and position, untouched by the sidebar's
   * collapse/width transitions).
   */
  logo?: ReactNode
  wordmark?: string
  items: SidebarNavItem[]
  /** A second nav group below a divider — e.g. Settings, kept apart from primary destinations. */
  secondaryItems?: SidebarNavItem[]
  /** Solo accounts have nothing to switch to — omit to hide the whole cluster. */
  workspaces?: SidebarWorkspace[]
  /** Section label above the workspace list — "Workspace", "Production studio", etc. */
  workspaceLabel?: string
  /** Icon-rail state (64px, matches Navigation Options' "1c" treatment) — omit for always-expanded. */
  collapsed?: boolean
  onToggleCollapsed?: () => void
  /**
   * Storefront's flush treatment: no boxed panel background — the sidebar sits
   * directly on the page's own surface (--bg-base) and only individual nav
   * items/pills carry their own background. Default (false) keeps the "1a"
   * boxed-panel look (--bg-surface) that Dashboard/CRM/History already use.
   */
  flush?: boolean
  /** Expanded-state width in px — 236 (Dashboard.dc.html) by default; collapsed always stays 64. */
  width?: number
  /** Optional slot between the logo and the primary nav list — e.g. a page-level primary action. */
  header?: ReactNode
  className?: string
}

function navItemClass(collapsed: boolean, active: boolean | undefined) {
  return cn(
    "flex items-center gap-[10px] overflow-hidden whitespace-nowrap border-none text-left text-[13px] transition-[width,border-radius,background-color] duration-200",
    collapsed ? "h-[38px] w-[38px] justify-center rounded-full" : "h-[34px] w-full rounded-[8px] px-[10px]",
    active
      ? "bg-[var(--bg-overlay)] text-[var(--text-primary)]"
      : "bg-transparent text-[var(--text-secondary)] hover:bg-[var(--ghost-hover)]",
    FOCUS_RING
  )
}

// Elevation Kit — SidebarNav: 236px, pinned full height. Nav rows 34px/8px
// radius (or a circle when collapsed — the "shrunken pill"), ghost-hover when
// inactive, surface/01 (--bg-overlay) fill when active. Workspace switcher
// pinned near the bottom — per T0016/T0040, omit `workspaces` entirely for
// solo (no-company) accounts rather than rendering a switcher with nothing to
// switch to. Collapsing to a 64px icon rail (labels replaced by title-attr
// tooltips) is opt-in via `collapsed`/`onToggleCollapsed` — omit both for a
// sidebar that's always full width. The collapse control itself is always
// icon-only, bottom-left — never a labeled row.
export function SidebarNav({
  logo,
  wordmark,
  items,
  secondaryItems,
  workspaces,
  workspaceLabel = "Workspace",
  collapsed = false,
  onToggleCollapsed,
  flush = false,
  width = 236,
  header,
  className,
}: SidebarNavProps) {
  return (
    <div
      style={{ width: collapsed ? 64 : width }}
      className={cn(
        "sticky top-0 flex h-full flex-none flex-col gap-[26px] box-border transition-[width] duration-200",
        flush ? "bg-transparent" : "bg-[var(--bg-surface)]",
        collapsed
          ? "items-center px-0 py-[22px]"
          : // flush (AppShell/Package Builder) sits directly under a TopBar whose
            // logo starts at 32px (px-8) — 22px left padding + a nav row's own
            // 10px inner padding lines the row icons up under the wordmark
            // (2026-08-10, at Darin's request). Non-flush (boxed-panel) usage
            // keeps the original 16px — it has no TopBar above it to align to.
            flush
            ? "p-[22px_22px]"
            : "p-[22px_16px]",
        className
      )}
    >
      {logo && (
        <div className={cn("flex items-center gap-[9px]", collapsed ? "justify-center" : "px-2")}>
          {logo}
          {!collapsed && wordmark && <span className="text-[14px] font-medium tracking-[-0.01em]">{wordmark}</span>}
        </div>
      )}

      {/* header (e.g. "Add gear") sits in its own tight-gap group with the primary
          nav list, so it reads as grouped right above Dashboard rather than
          floating in the wider 26px rhythm used between the other sections.
          Extra top margin drops the whole group lower in the rail, away from
          the logo, at Darin's request. */}
      <div className={cn("flex flex-col gap-2 mt-[36px]", collapsed && "items-center")}>
        {header && <div className={cn("flex flex-col", collapsed && "items-center")}>{header}</div>}

        <nav className={cn("flex flex-col gap-0.5", collapsed && "items-center")}>
          {items.map((item) => (
            <button
              key={item.label}
              type="button"
              title={collapsed ? item.label : undefined}
              onClick={item.onClick}
              className={navItemClass(collapsed, item.active)}
            >
              {item.icon}
              {!collapsed && item.label}
            </button>
          ))}
        </nav>
      </div>

      {secondaryItems && secondaryItems.length > 0 && (
        <nav className={cn("flex flex-col gap-0.5 border-t border-[var(--elevation-divider)] pt-[14px]", collapsed && "items-center")}>
          {secondaryItems.map((item) => (
            <button
              key={item.label}
              type="button"
              title={collapsed ? item.label : undefined}
              onClick={item.onClick}
              className={navItemClass(collapsed, item.active)}
            >
              {item.icon}
              {!collapsed && item.label}
            </button>
          ))}
        </nav>
      )}

      {workspaces && workspaces.length > 0 && (
        <div className={cn("mt-auto flex flex-col gap-2.5", collapsed && "items-center")}>
          {!collapsed && (
            <span className="px-[10px] text-[11px] font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]">
              {workspaceLabel}
            </span>
          )}
          <div className={cn("flex flex-col gap-1.5", collapsed && "items-center")}>
            {workspaces.map((ws) => (
              <button
                key={ws.name}
                type="button"
                title={collapsed ? ws.name : undefined}
                onClick={ws.onClick}
                className={cn(
                  "flex gap-[10px] border-none text-left transition-[width,border-radius,background-color] duration-200",
                  // Collapsed clips/no-wraps (icon only, avoids the collapse-
                  // transition flicker); expanded allows the name to wrap —
                  // at a narrow sidebar width, a long company name needs it,
                  // so the icon aligns to the top of the (possibly 2-line) name.
                  collapsed
                    ? "h-9 w-9 items-center justify-center overflow-hidden whitespace-nowrap rounded-full"
                    : "w-full items-start rounded-[14px] px-3 py-[11px]",
                  ws.active ? "bg-[var(--bg-overlay)] shadow-[var(--elevation-1)]" : "bg-transparent",
                  FOCUS_RING
                )}
              >
                <span className="flex-none">{ws.icon}</span>
                {!collapsed && <span className="text-[12.5px] font-medium leading-snug">{ws.name}</span>}
              </button>
            ))}
          </div>
        </div>
      )}

      {onToggleCollapsed && (
        <button
          type="button"
          title={collapsed ? "Expand sidebar" : "Collapse sidebar"}
          aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
          onClick={onToggleCollapsed}
          className={cn(
            "flex h-7 w-7 flex-none items-center justify-center rounded-[7px] border-none text-[var(--text-muted)] transition-colors hover:bg-[var(--ghost-hover)] hover:text-[var(--text-secondary)]",
            !collapsed && "self-start",
            !workspaces?.length && "mt-auto",
            FOCUS_RING
          )}
        >
          {collapsed ? <PanelLeftOpen size={15} strokeWidth={1.7} /> : <PanelLeftClose size={15} strokeWidth={1.7} />}
        </button>
      )}
    </div>
  )
}
