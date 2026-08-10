import { redirect } from "next/navigation"
import { getProducts, getRentalHouseInventory, getProduction, getPackageByProduction, getPackageItems, getCompany, getPackageComments, getMentionableUsers, getPackageEvents, type ProductCard, type RentalHouseRate } from "@/lib/db/queries"
import { getViewerContext } from "@/lib/viewer-context"
import { PackageBuilderClient } from "./package-builder-client"
import type { GearCategory, GearItem, PackageLineItem } from "./types"

// Fallback only — used when a signed-in user has no production_members row
// (or nobody is signed in yet) and only safe while there's exactly one
// seeded production in this single-tenant demo state: Harpeth Valley
// Studios / Top Gun Maverick, seeded 2026-08-05 (see
// docs/tasks/finished/T0004-seed-demo-production.md). Real production
// selection/routing (a user with multiple productions choosing one) is a
// separate, bigger feature — TODO(T00xx).
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
  const viewer = await getViewerContext()
  // T0019 — see (app)/layout.tsx for the same gate; package-builder sits
  // under its own (workspace) route group so it needs its own check.
  if (viewer && !viewer.onboardingCompletedAt) redirect("/signup")
  const productionId = viewer?.productionId ?? DEMO_PRODUCTION_ID

  const [products, vendorRateRows, production, pkg] = await Promise.all([
    getProducts({ brandSlug: "canon", limit: 200 }),
    getRentalHouseInventory(VENDOR_SLUG),
    getProduction(productionId),
    getPackageByProduction(productionId),
  ])
  const vendorRates = new Map(vendorRateRows.map((r) => [r.productId, r]))
  const company = production ? await getCompany(production.companyId) : null

  const catalog = products
    .map((p) => toGearItem(p, vendorRates))
    .filter((g): g is GearItem => g !== null)

  const shootDays = production?.shootDays ?? 18
  const approvedBudget = production?.totalBudget ?? 105_880

  // Real persisted line items — see docs/tasks/T0005. Falls back to an empty
  // package (not fake data) if the package row itself is somehow missing.
  const [packageItemRows, comments, mentionableUsers, events] = await Promise.all([
    pkg ? getPackageItems(pkg.id) : Promise.resolve([]),
    pkg ? getPackageComments(pkg.id) : Promise.resolve([]),
    getMentionableUsers(productionId),
    pkg ? getPackageEvents(pkg.id) : Promise.resolve([]),
  ])
  const initialLineItems: PackageLineItem[] = packageItemRows.map((row) => ({
    id: row.id,
    gearId: row.gearId,
    qty: row.qty,
    days: shootDays,
    status: row.status as PackageLineItem["status"],
    notesCount: 0, // package-level comments, not per-line — see docs/tasks/T0008
  }))
  const initialComments = comments.map((c) => ({
    id: c.id,
    body: c.body,
    createdAt: c.createdAt.toISOString(),
    updatedAt: c.updatedAt ? c.updatedAt.toISOString() : null,
    authorId: c.authorId,
    authorName: c.authorName,
    mentionedUserIds: c.mentionedUserIds,
  }))
  const initialEvents = events.map((e) => ({
    id: e.id,
    kind: e.kind,
    payload: e.payload,
    createdAt: e.createdAt.toISOString(),
    actorName: e.actorName,
  }))

  return (
    <PackageBuilderClient
      catalog={catalog}
      initialLineItems={initialLineItems}
      productionName={production?.name ?? "Untitled Production"}
      packageName={pkg?.name ?? "Camera Package"}
      packageId={pkg?.id ?? null}
      productionId={productionId}
      viewerId={viewer?.user.id ?? null}
      updatedAt={pkg?.updatedAt.toISOString() ?? null}
      shootDays={shootDays}
      approvedBudget={approvedBudget}
      userName={viewer?.user.name ?? "Guest"}
      companyName={company?.name ?? null}
      initialComments={initialComments}
      mentionableUsers={mentionableUsers}
      initialEvents={initialEvents}
    />
  )
}
