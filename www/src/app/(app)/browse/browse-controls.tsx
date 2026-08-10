import Link from "next/link"
import { ChevronLeft, ChevronRight, SlidersHorizontal } from "lucide-react"
import { GEAR_GROUP_LABELS, GEAR_GROUP_ORDER, type GearGroup } from "@/lib/gear-taxonomy"

// Tab row above the grid — 2026-08-10, replaced the earlier brand-based tabs
// with the same 5-department grouping Package Builder's grid already uses
// (camera/lenses/support/focus/video, see lib/gear-taxonomy.ts), now that
// the page-local category sidebar is gone (single global left nav only).
// Brand stays a real, useful filter axis — it just moves into the (not yet
// built) filter panel instead of living as tabs.
export function BrowseTabs({
  counts,
  activeGroup,
  totalCount,
  buildHref,
}: {
  counts: Record<GearGroup, number>
  activeGroup: GearGroup | undefined
  totalCount: number
  buildHref: (next: { group: string | null; page?: number }) => string
}) {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-[var(--elevation-divider)] px-1 pb-0 pt-2">
      <div className="flex items-center gap-7 overflow-x-auto">
        <Tab href={buildHref({ group: null, page: 1 })} label="All" count={totalCount} active={!activeGroup} />
        {GEAR_GROUP_ORDER.map((group) => (
          <Tab
            key={group}
            href={buildHref({ group, page: 1 })}
            label={GEAR_GROUP_LABELS[group]}
            count={counts[group]}
            active={activeGroup === group}
          />
        ))}
      </div>
      {/* Static for now — real filter fields (brand + mount type look like
          the strongest real candidates from the data; see conversation) get
          scoped and wired as a follow-up, not part of this pass. */}
      <button
        type="button"
        disabled
        title="Filters — coming soon"
        className="mb-2 flex flex-none cursor-default items-center gap-2 rounded-full bg-[var(--surface-02)] px-3.5 py-2 text-xs text-[var(--text-muted)] shadow-[var(--elevation-1)]"
      >
        <SlidersHorizontal size={13} strokeWidth={1.8} />
        Filter
      </button>
    </div>
  )
}

function Tab({ href, label, count, active }: { href: string; label: string; count: number; active: boolean }) {
  return (
    <Link
      href={href}
      className="flex items-center gap-1.5 whitespace-nowrap pb-[11px] text-xs transition-colors"
      style={{
        color: active ? "var(--text-primary)" : "var(--text-muted)",
        fontWeight: active ? 500 : 400,
        borderBottom: active ? "2px solid var(--text-primary)" : "2px solid transparent",
      }}
    >
      {label}
      <span className="font-mono text-[10px] text-[var(--text-subtle)]">{count}</span>
    </Link>
  )
}

export function BrowsePagination({
  page,
  totalPages,
  buildHref,
}: {
  page: number
  totalPages: number
  buildHref: (next: { page: number }) => string
}) {
  if (totalPages <= 1) return null

  const prevDisabled = page <= 1
  const nextDisabled = page >= totalPages

  return (
    <div className="flex items-center justify-center gap-3 pt-2">
      <PagerButton href={prevDisabled ? undefined : buildHref({ page: page - 1 })} disabled={prevDisabled} aria-label="Previous page">
        <ChevronLeft size={15} strokeWidth={2} />
      </PagerButton>
      <span className="font-mono text-[11px] text-[var(--text-muted)]">
        Page {page} of {totalPages}
      </span>
      <PagerButton href={nextDisabled ? undefined : buildHref({ page: page + 1 })} disabled={nextDisabled} aria-label="Next page">
        <ChevronRight size={15} strokeWidth={2} />
      </PagerButton>
    </div>
  )
}

// Link-based twin of IconButton/circle (pager tone) — IconButton itself
// renders a <button>, which can't navigate via href without going client-side;
// pagination stays server-rendered/URL-driven per T0020, so this mirrors its
// visual spec directly instead.
function PagerButton({
  href,
  disabled,
  children,
  "aria-label": ariaLabel,
}: {
  href?: string
  disabled?: boolean
  children: React.ReactNode
  "aria-label": string
}) {
  const className = "inline-flex h-10 w-10 flex-none items-center justify-center rounded-full text-[var(--text-primary)] transition-colors"
  if (disabled || !href) {
    return (
      <span aria-hidden className={`${className} cursor-default bg-[var(--surface-disabled)] text-[var(--text-subtle)] opacity-60`}>
        {children}
      </span>
    )
  }
  return (
    <Link
      href={href}
      aria-label={ariaLabel}
      className={`${className} bg-[var(--surface-02)] shadow-[var(--elevation-1)] hover:bg-[var(--surface-02-hover)]`}
    >
      {children}
    </Link>
  )
}
