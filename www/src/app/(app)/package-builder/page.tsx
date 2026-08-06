import { getProducts, getRentalHouseInventory, getProduction, getPackageByProduction, type ProductCard, type RentalHouseRate } from "@/lib/db/queries"
import { PackageBuilderClient } from "./package-builder-client"
import type { GearCategory, GearItem, PackageLineItem } from "./types"

// Hardcoded until real production selection/routing exists (single-tenant
// demo state) — Harpeth Valley Studios / Top Gun Maverick, seeded 2026-08-05
// (see docs/tasks/T0004-seed-demo-production.md).
const DEMO_PRODUCTION_ID = "3bd8e7c3-d0a0-4382-960c-c104c472a6ee"

// categorySlug (product_category) → the 5-group taxonomy the builder grid uses.
// Only camera + lenses have real catalog data today — support/focus/video stay
// empty ("empty — add") until the pipeline covers those product types.
const CATEGORY_MAP: Record<string, GearCategory> = {
  "cinema-cameras": "camera",
  "mirrorless-cameras": "camera",
  "cinema-lenses": "lenses",
  lenses: "lenses",
}

const VENDOR_SLUG = "davinci-rentals"

// Placeholder day-rate estimate (≈1.2% of MSRP/day, roughly matching real-world
// cinema rental pricing) — used only when no real DaVinci Rentals row exists yet
// for this product. Real rates always win over this.
function estimateDayRate(msrpUsd: string | null, category: GearCategory): number {
  const msrp = msrpUsd ? parseFloat(msrpUsd) : null
  if (msrp && msrp > 0) return Math.max(25, Math.round((msrp * 0.012) / 5) * 5)
  return category === "camera" ? 250 : 65
}

function toGearItem(
  p: ProductCard,
  vendorRates: Map<string, RentalHouseRate>
): GearItem | null {
  const category = CATEGORY_MAP[p.categorySlug]
  if (!category) return null

  const vendor = vendorRates.get(p.id)
  const rate = vendor
    ? {
        dayRate: vendor.dayRate,
        weekRate: vendor.weekRate,
        source: "vendor" as const,
        vendorName: vendor.rentalHouseName,
        quantityOnHand: vendor.quantityOnHand,
      }
    : {
        dayRate: estimateDayRate(p.msrpUsd, category),
        weekRate: null,
        source: "estimate" as const,
      }

  return {
    id: p.id,
    slug: p.slug,
    name: p.fullName,
    sku: p.model,
    category,
    brandName: p.brandName,
    imageUrl: p.primaryImageUrl,
    rate,
  }
}

export default async function PackageBuilderPage() {
  const [products, vendorRateRows, production, pkg] = await Promise.all([
    getProducts({ brandSlug: "canon", limit: 200 }),
    getRentalHouseInventory(VENDOR_SLUG),
    getProduction(DEMO_PRODUCTION_ID),
    getPackageByProduction(DEMO_PRODUCTION_ID),
  ])
  const vendorRates = new Map(vendorRateRows.map((r) => [r.productId, r]))

  const catalog = products
    .map((p) => toGearItem(p, vendorRates))
    .filter((g): g is GearItem => g !== null)

  // Seed a starting package so the grid isn't empty on first load — prefer real
  // DaVinci-stocked items so the demo leads with real numbers, then fall back to
  // one estimate-rate lens so both rate sources are visible on first load.
  const vendorCamera = catalog.find((g) => g.category === "camera" && g.rate.source === "vendor")
  const vendorLens = catalog.find((g) => g.category === "lenses" && g.rate.source === "vendor")
  const estimateLens = catalog.find(
    (g) => g.category === "lenses" && g.rate.source === "estimate" && g.id !== vendorLens?.id
  )
  const seedGear = [vendorCamera, vendorLens, estimateLens].filter((g): g is GearItem => Boolean(g))

  const shootDays = production?.shootDays ?? 18
  const approvedBudget = production?.totalBudget ?? 105_880

  const initialLineItems: PackageLineItem[] = seedGear.map((g, i) => ({
    id: `seed-${g.id}`,
    gearId: g.id,
    qty: 1,
    days: shootDays,
    status: i === 0 ? "sent" : "draft",
    notesCount: i === 0 ? 1 : 0,
  }))

  return (
    <PackageBuilderClient
      catalog={catalog}
      initialLineItems={initialLineItems}
      productionName={production?.name ?? "Untitled Production"}
      packageName={pkg?.name ?? "Camera Package"}
      shootDays={shootDays}
      approvedBudget={approvedBudget}
    />
  )
}
