import Link from "next/link"
import { ChevronLeft, ChevronRight } from "lucide-react"
import type { CategoryCount } from "@/lib/db/queries"

// Tab row above the grid. The mockup's tabs are curated category shortcuts
// ("All / Rental houses / Cameras / Lenses / ..."); real data only supports
// category and brand as filterable axes today (see T0020 task notes), and
// category already has its own affordance in the page-local sidebar — so
// this row uses brand as the second, real axis instead of inventing/
// hardcoding tab labels the catalog can't back up. "Rental houses" browsing
// is a distinct, unbuilt feature (no vendor-browse UI exists) and stays out
// of scope here.
export function BrowseTabs({
  brands,
  activeSlug,
  buildHref,
}: {
  brands: CategoryCount[]
  activeSlug: string | undefined
  buildHref: (next: { tab: string | null; page?: number }) => string
}) {
  return (
    <div className="flex items-center gap-7 overflow-x-auto border-b border-[var(--elevation-divider)] px-1 pb-0 pt-2">
      <Tab href={buildHref({ tab: null, page: 1 })} label="All" active={!activeSlug} />
      {brands.map((b) => (
        <Tab key={b.slug} href={buildHref({ tab: b.slug, page: 1 })} label={b.name} active={activeSlug === b.slug} />
      ))}
    </div>
  )
}

function Tab({ href, label, active }: { href: string; label: string; active: boolean }) {
  return (
    <Link
      href={href}
      className="whitespace-nowrap pb-[11px] text-xs transition-colors"
      style={{
        color: active ? "var(--text-primary)" : "var(--text-muted)",
        fontWeight: active ? 500 : 400,
        borderBottom: active ? "2px solid var(--text-primary)" : "2px solid transparent",
      }}
    >
      {label}
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
