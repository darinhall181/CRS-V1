import type { ReactNode } from "react"
import Link from "next/link"
import { Search, Bell } from "lucide-react"
import { cn } from "@/lib/utils"
import { FOCUS_RING } from "./shared"

export interface TopBarProps {
  logo: ReactNode
  wordmark: string
  searchPlaceholder?: string
  searchValue?: string
  onSearchChange?: (value: string) => void
  onNotificationsClick?: () => void
  /** Right-most slot — avatar/name/dropdown. The app owns whatever's inside
   * (auth, sign-out, workspace switching) — this primitive just reserves the
   * spot next to the notification bell. */
  userMenu?: ReactNode
  className?: string
}

// Elevation Kit — TopBar: full-width global header (Package Builder's flush
// treatment, T0016/T0034 layout family). Sits above the sidebar rather than
// beside it — a page composes <TopBar /> then, below it, a row of
// <SidebarNav /> + content, so the sidebar starts under the bar instead of
// hitting the top of the viewport (2026-08-08, at Darin's direction).
//
// Logo/wordmark live here, not in SidebarNav, so branding stays a fixed
// size/position regardless of the sidebar's collapse/width transitions —
// SidebarNav's own `logo`/`wordmark` props exist only for layouts that don't
// use a TopBar at all (see SidebarNav's ProductionWithWorkspaces story).
//
// Logo/wordmark link to /dashboard (2026-08-10, at Darin's request) — the
// conventional "click the brand mark to go home" affordance.
//
// mt-8 (32px) pushes the row down from the true top of the screen to match
// the 32px pt-8 a page composing this typically gives its own title row
// below — keeps the gap above and below the bar visually even.
export function TopBar({
  logo,
  wordmark,
  searchPlaceholder = "Search…",
  searchValue,
  onSearchChange,
  onNotificationsClick,
  userMenu,
  className,
}: TopBarProps) {
  return (
    <div className={cn("mt-8 flex h-[42px] flex-none items-center gap-5 bg-[var(--bg-base)] px-8", className)}>
      <Link
        href="/dashboard"
        className={cn(
          "flex flex-none items-center gap-[11px] rounded-[8px] transition-opacity hover:opacity-80",
          FOCUS_RING
        )}
      >
        {logo}
        <span className="whitespace-nowrap text-[17px] font-medium tracking-[-0.01em]">{wordmark}</span>
      </Link>

      <div className="flex flex-1 justify-center">
        <div className="flex h-[42px] w-full max-w-[560px] items-center gap-2.5 rounded-full bg-[var(--surface-01)] px-4">
          <Search size={15} strokeWidth={2} className="text-[var(--text-muted)]" />
          <input
            type="text"
            value={searchValue}
            onChange={(e) => onSearchChange?.(e.target.value)}
            placeholder={searchPlaceholder}
            className="flex-1 bg-transparent text-[13px] text-[var(--text-primary)] outline-none placeholder:text-[var(--text-subtle)]"
          />
        </div>
      </div>

      <div className="flex flex-none items-center gap-4">
        <button
          type="button"
          aria-label="Notifications"
          onClick={onNotificationsClick}
          className={cn(
            "flex h-[38px] w-[38px] items-center justify-center rounded-full text-[var(--text-secondary)] transition-colors hover:bg-[var(--ghost-hover)]",
            FOCUS_RING
          )}
        >
          <Bell size={20} strokeWidth={1.8} />
        </button>
        {userMenu}
      </div>
    </div>
  )
}
