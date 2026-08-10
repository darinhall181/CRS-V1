import type { CategoryCount } from "./db/queries"

// Browse's category tabs (T0020 follow-up, 2026-08-10) group the ~47 raw
// `product_category` rows into the same 5-department shape Package Builder's
// grid already uses (see (workspace)/package-builder/types.ts's GearCategory)
// — camera crews think in "camera / lenses / support / focus / video", not
// in scrape-source category slugs. This is Browse's own mapping (not a
// shared import from package-builder) since package-builder's CATEGORY_MAP
// is deliberately narrower today (Canon-only catalog, only 4 slugs mapped —
// see that file's comment); this one covers every real category slug so the
// tabs' counts are accurate regardless of which brands/categories the
// pipeline has scraped.
export type GearGroup = "camera" | "lenses" | "support" | "focus" | "video"

export const GEAR_GROUP_LABELS: Record<GearGroup, string> = {
  camera: "Camera",
  lenses: "Lenses",
  support: "Support",
  focus: "Focus / AC",
  video: "Video / Monitoring",
}

export const GEAR_GROUP_ORDER: GearGroup[] = ["camera", "lenses", "support", "focus", "video"]

const CATEGORY_SLUG_TO_GROUP: Record<string, GearGroup> = {
  // camera
  cameras: "camera",
  "mirrorless-cameras": "camera",
  "dslr-cameras": "camera",
  "cinema-cameras": "camera",
  camcorders: "camera",
  "action-cameras": "camera",
  "compact-cameras": "camera",
  "medium-format-cameras": "camera",
  "film-cameras": "camera",
  "360-cameras": "camera",
  // lenses
  "mirrorless-lenses": "lenses",
  lenses: "lenses",
  "dslr-lenses": "lenses",
  "cinema-lenses": "lenses",
  "cinema-prime-sets-pl": "lenses",
  "cinema-prime-sets-lpl": "lenses",
  "cinema-zoom-lenses": "lenses",
  "anamorphic-lenses": "lenses",
  "rangefinder-lenses": "lenses",
  teleconverters: "lenses",
  "lens-filters": "lenses",
  "lens-adapters": "lenses",
  "cinema-lens-adapters": "lenses",
  // support (grip, rigging, power, and everything without its own
  // department above — a deliberate catch-all, same role "Support" plays
  // in the package-builder grid)
  "fluid-heads": "support",
  "tripods-legs": "support",
  "support-grip": "support",
  "camera-support": "support",
  "baseplates-rails": "support",
  "camera-cages-rigging": "support",
  "matte-boxes": "support",
  "bags-cases": "support",
  accessories: "support",
  "drones-aerial": "support",
  "battery-adapters": "support",
  "batteries-gold-mount": "support",
  "batteries-v-mount": "support",
  "power-batteries": "support",
  audio: "support",
  lighting: "support",
  // focus
  "follow-focus-fiz": "focus",
  // video / monitoring
  "on-board-monitors": "video",
  "monitors-displays": "video",
  "directors-monitors": "video",
  "wireless-video": "video",
  "monitors-recorders": "video",
  "recording-media": "video",
  "storage-media": "video",
}

export function groupForCategorySlug(categorySlug: string): GearGroup | null {
  return CATEGORY_SLUG_TO_GROUP[categorySlug] ?? null
}

/** Raw product_category slugs belonging to a group, restricted to ones that
 * actually exist in `categories` (so a query never filters on a slug the DB
 * doesn't have). */
export function slugsForGroup(group: GearGroup, categories: CategoryCount[]): string[] {
  return categories.filter((c) => CATEGORY_SLUG_TO_GROUP[c.slug] === group).map((c) => c.slug)
}

/** Real product counts per group, derived from getCategoriesWithCounts() —
 * never hardcoded, so a group's count always reflects the actual catalog. */
export function countsByGroup(categories: CategoryCount[]): Record<GearGroup, number> {
  const counts: Record<GearGroup, number> = { camera: 0, lenses: 0, support: 0, focus: 0, video: 0 }
  for (const c of categories) {
    const group = CATEGORY_SLUG_TO_GROUP[c.slug]
    if (group) counts[group] += c.count
  }
  return counts
}
