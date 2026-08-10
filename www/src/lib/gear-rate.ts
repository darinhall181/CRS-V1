import type { RentalHouseRate } from "@/lib/db/queries"

// Shared day-rate resolution — real vendor quote when one exists, else a
// rough estimate. Originally lived only in package-builder/page.tsx
// (toGearItem/estimateDayRate); extracted here (T0020) so Browse can use the
// exact same heuristic instead of silently drifting from it. Real rates
// always win over the estimate; callers must surface `source` in the UI
// (badge/label) rather than presenting an estimate as a real quote — see
// package-builder-client.tsx's "Not confirmed" treatment for the pattern.

export type GearRateSource = "vendor" | "estimate"

export interface GearRate {
  dayRate: number
  weekRate: number | null
  source: GearRateSource
  vendorName?: string
  quantityOnHand?: number | null
}

// ≈1.2% of MSRP/day, roughly matching real-world cinema rental pricing —
// used only when no real rental-house row exists yet for this product.
export function estimateDayRate(msrpUsd: string | null, fallback: number = 65): number {
  const msrp = msrpUsd ? parseFloat(msrpUsd) : null
  if (msrp && msrp > 0) return Math.max(25, Math.round((msrp * 0.012) / 5) * 5)
  return fallback
}

export function resolveGearRate(
  productId: string,
  msrpUsd: string | null,
  vendorRates: Map<string, RentalHouseRate>,
  fallback: number = 65
): GearRate {
  const vendor = vendorRates.get(productId)
  if (vendor) {
    return {
      dayRate: vendor.dayRate,
      weekRate: vendor.weekRate,
      source: "vendor",
      vendorName: vendor.rentalHouseName,
      quantityOnHand: vendor.quantityOnHand,
    }
  }
  return { dayRate: estimateDayRate(msrpUsd, fallback), weekRate: null, source: "estimate" }
}
