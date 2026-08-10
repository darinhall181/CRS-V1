import {
  getProducts,
  getProductsCount,
  getCategoriesWithCounts,
  getBrandsWithCounts,
  getRentalHouseInventory,
  getPackageByProduction,
} from "@/lib/db/queries"
import { getViewerContext } from "@/lib/viewer-context"
import { resolveGearRate } from "@/lib/gear-rate"
import { BrowseSidebar } from "./browse-sidebar"
import { BrowseTabs, BrowsePagination } from "./browse-controls"
import { BrowseGrid, type BrowseGridProduct } from "./browse-grid"

export const dynamic = "force-dynamic"

export const metadata = {
  title: "Browse — Altoscope",
  description: "Browse all cameras and lenses in the Altoscope database.",
}

// Same demo-fallback production used by package-builder/(app) layout — see
// those files for the full rationale (single-tenant demo state).
const DEMO_PRODUCTION_ID = "3bd8e7c3-d0a0-4382-960c-c104c472a6ee"
const VENDOR_SLUG = "davinci-rentals"
const PAGE_SIZE = 24

interface PageProps {
  searchParams: { category?: string; tab?: string; page?: string }
}

// Storefront layout (T0020): 224px page-local category sidebar, a brand tab
// row, and a real paginated product grid — all state (category, tab, page)
// lives in searchParams so results are shareable and the back button works
// for free. The mockup's curated homepage content (hero banner, "Featured
// picks"/"Recommended"/"Prep-day essentials" rows, star ratings, saved/heart
// toggle) is explicitly out of scope — see T0022/T0023 and this file's
// finished-task notes.
export default async function BrowsePage({ searchParams }: PageProps) {
  const categorySlug = searchParams.category || undefined
  const brandSlug = searchParams.tab || undefined
  const page = Math.max(1, parseInt(searchParams.page ?? "1", 10) || 1)
  const offset = (page - 1) * PAGE_SIZE

  const viewer = await getViewerContext()
  const productionId = viewer?.productionId ?? DEMO_PRODUCTION_ID

  const [products, total, categories, brands, vendorRateRows, pkg] = await Promise.all([
    getProducts({ categorySlug, brandSlug, limit: PAGE_SIZE, offset }),
    getProductsCount({ categorySlug, brandSlug }),
    getCategoriesWithCounts(),
    getBrandsWithCounts(categorySlug),
    getRentalHouseInventory(VENDOR_SLUG),
    getPackageByProduction(productionId),
  ])

  const vendorRates = new Map(vendorRateRows.map((r) => [r.productId, r]))
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE))
  const totalCatalog = categories.reduce((sum, c) => sum + c.count, 0)

  const gridProducts: BrowseGridProduct[] = products.map((p) => {
    const rate = resolveGearRate(p.id, p.msrpUsd, vendorRates)
    return {
      id: p.id,
      name: p.fullName,
      spec: `${p.brandName} · ${p.categoryName}`,
      imageUrl: p.primaryImageUrl,
      rate: rate.dayRate,
      rateSource: rate.source,
    }
  })

  function buildHref(next: { category?: string | null; tab?: string | null; page?: number }) {
    const params = new URLSearchParams()
    const category = next.category !== undefined ? next.category : categorySlug ?? null
    const tab = next.tab !== undefined ? next.tab : brandSlug ?? null
    const nextPage = next.page !== undefined ? next.page : page
    if (category) params.set("category", category)
    if (tab) params.set("tab", tab)
    if (nextPage && nextPage > 1) params.set("page", String(nextPage))
    const qs = params.toString()
    return qs ? `/browse?${qs}` : "/browse"
  }

  const activeCategoryName = categorySlug ? categories.find((c) => c.slug === categorySlug)?.name : null

  return (
    <div className="px-9 py-8">
      <div className="grid gap-6" style={{ gridTemplateColumns: "224px minmax(0,1fr)" }}>
        <BrowseSidebar categories={categories} activeSlug={categorySlug} totalCount={totalCatalog} buildHref={buildHref} />

        <main className="flex min-w-0 flex-col gap-5">
          <BrowseTabs brands={brands} activeSlug={brandSlug} buildHref={buildHref} />

          <div className="flex items-baseline justify-between px-1">
            <h1 className="m-0 text-lg font-medium tracking-[-0.01em] text-[var(--text-primary)]">
              {activeCategoryName ?? "All gear"}
            </h1>
            <p className="m-0 text-xs text-[var(--text-muted)]">
              {total} {total === 1 ? "item" : "items"}
            </p>
          </div>

          {gridProducts.length > 0 ? (
            <BrowseGrid products={gridProducts} packageId={pkg?.id ?? null} />
          ) : (
            <div className="flex flex-col items-center gap-1 py-24 text-center">
              <p className="m-0 text-sm text-[var(--text-secondary)]">No gear found here yet.</p>
              <p className="m-0 text-xs text-[var(--text-subtle)]">
                Pipeline coverage today is cameras + lenses — other departments fill in as scraping expands.
              </p>
            </div>
          )}

          <BrowsePagination page={page} totalPages={totalPages} buildHref={buildHref} />
        </main>
      </div>
    </div>
  )
}
