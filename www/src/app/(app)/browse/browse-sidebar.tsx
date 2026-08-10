import Link from "next/link"
import { Grid3x3 } from "lucide-react"
import type { CategoryCount } from "@/lib/db/queries"

// Page-local secondary sidebar (224px, 40px rows, 10px radius, per the
// Storefront mockup) — deliberately NOT the global SidebarNav primitive
// (that's the app-wide left nav rendered by AppShell one level up). This is
// page content: a category filter for the product grid, so it's plain
// markup scoped to this route. Real categories + counts only
// (getCategoriesWithCounts already excludes categories with zero active
// products, so pipeline coverage gaps show up truthfully as an absent row
// rather than a fake "0 items" entry).
export function BrowseSidebar({
  categories,
  activeSlug,
  totalCount,
  buildHref,
}: {
  categories: CategoryCount[]
  activeSlug: string | undefined
  totalCount: number
  buildHref: (next: { category: string | null; page?: number }) => string
}) {
  return (
    <nav className="flex flex-col gap-0.5 pt-1">
      <Row href={buildHref({ category: null, page: 1 })} label="All categories" count={totalCount} active={!activeSlug} icon={<Grid3x3 size={16} strokeWidth={1.8} />} />
      {categories.map((cat) => (
        <Row
          key={cat.slug}
          href={buildHref({ category: cat.slug, page: 1 })}
          label={cat.name}
          count={cat.count}
          active={activeSlug === cat.slug}
        />
      ))}
    </nav>
  )
}

function Row({
  href,
  label,
  count,
  active,
  icon,
}: {
  href: string
  label: string
  count: number
  active: boolean
  icon?: React.ReactNode
}) {
  return (
    <Link
      href={href}
      className="flex h-10 items-center justify-between gap-2 rounded-[10px] px-3.5 text-xs transition-colors"
      style={{
        background: active ? "var(--surface-02)" : "transparent",
        color: active ? "var(--text-primary)" : "var(--text-muted)",
        fontWeight: active ? 500 : 400,
      }}
    >
      <span className="flex items-center gap-3 truncate">
        {icon}
        <span className="truncate">{label}</span>
      </span>
      <span className="font-mono text-[10px] text-[var(--text-subtle)]">{count}</span>
    </Link>
  )
}
