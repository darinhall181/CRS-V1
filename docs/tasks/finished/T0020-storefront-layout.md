---
title: Rework /browse into the Storefront layout (sidebar, tabs, card grid, pagination)
status: done
severity: high
type: task
component: www/src/app/(app)/browse/
found_by: claude-code
found_date: 2026-08-08
completed_date: 2026-08-10
verified_live: true
github_issue: null
---

## Summary
Batch 2 (Storefront), 1 of 4. Rebuild the browse page to the `Altoscope Storefront.dc.html`
layout: 224px category sidebar, tab row, 5-col gear card grid (surface/02, 12px radius,
elevation/1, mono rate + unit, add-to-package button), bottom panels. Server-rendered from
real data; all browse state in the URL (`searchParams`) — category, tab, page — so results
are shareable and the back button is free.

- Sidebar renders from `product_category` + `getCategoriesWithCounts()` — NOT the mockup's
  hardcoded 11 categories. Pipeline coverage today is cameras + lenses only; the sidebar
  should tell the truth (other departments appear as they gain data).
- Card rate: `rental_house_inventory` day rate when present, else the existing
  `estimateDayRate` heuristic (mark estimates visually — same honesty rule).
- Pagination: extend `getProducts` with offset/count; pager per design system.
- Add-to-package button reuses `addPackageItemAction` (already exists) against the current
  package; wire the nav badge count (T0016).

## Notes
Star ratings on cards: DEFERRED — no ratings data source exists anywhere in the schema.
Render cards without the rating row (the prototype's own `showRatings` prop anticipates
this). Revisit only when a real source exists.

## Summary (2026-08-10)
Rebuilt `/browse` as a real, server-rendered, URL-driven storefront grid — no more
light-shadcn styling, no more client-side-only filtering.

**Built:**
- `www/src/app/(app)/browse/page.tsx` — server component, all state
  (`?category=&tab=&page=`) in `searchParams`. 224px page-local category sidebar
  (`browse-sidebar.tsx`, plain `<nav>`/`Link` markup, deliberately NOT the global
  `SidebarNav` primitive — that's the app-wide left nav AppShell already renders one
  level up) + a brand tab row (`browse-controls.tsx`) + a 5-col `GearCard` grid
  (`browse-grid.tsx`) + pagination.
- Sidebar renders from real `getCategoriesWithCounts()` — 13 real categories with real
  counts today (lenses 123, cinema-lenses 50, cinema-cameras 20, cinema-prime-sets-pl 17,
  mirrorless-cameras 15, plus several 1-count categories), not the mockup's hardcoded 11.
  Zero-count categories are already excluded by the query, so coverage gaps show up
  truthfully as an absent row.
- Tab row is brand-driven (`getBrandsWithCounts`, new), not the mockup's curated/hardcoded
  labels ("All / Rental houses / Cameras / Lenses / ..."). Real data only supports category
  and brand as filterable axes; category already has the sidebar, so brand is the tab row's
  real second axis. "Rental houses" browsing (a distinct vendor-browse UI) doesn't exist and
  stays out of scope.
- Pagination: `getProducts` gained `offset`; new `getProductsCount` (same filter builder,
  `productFilters()`, shared between both so they can't drift on what counts as a "match").
  24/page. Verified reachable live: `/browse?category=lenses` → "Page 1 of 6", confirmed
  page 2 navigates and renders a different row of products.
- Rate heuristic extracted to `www/src/lib/gear-rate.ts` (`resolveGearRate`/
  `estimateDayRate`) — previously lived only in `package-builder/page.tsx`; both Browse and
  Package Builder now call the same function so the two can't silently diverge. Real
  DaVinci Rentals rate wins when present (`rate.source === "vendor"`, plain `/day` unit);
  else falls back to the ≈1.2%-of-MSRP estimate (`source === "estimate"`, unit reads
  `/day est.` on the card — the honesty-rule marking). Confirmed both states render live:
  most cards show the estimate suffix, EOS R5 C shows a real vendor rate with no suffix.
- Add-to-package reuses the existing `addPackageItemAction` against the current viewer's
  package (`getViewerContext` → `getPackageByProduction`, same `DEMO_PRODUCTION_ID`
  fallback pattern as Package Builder). Interactivity isolated to a small client component
  (`browse-grid.tsx`) — everything else on the page is a server component.

**Explicitly deferred (not built here):**
- Hero banner, "Featured picks"/"Recommended"/"Prep-day essentials" curated rows — T0022,
  blocked on content-curation decisions.
- Star ratings — no data source, per this task's own notes.
- Saved/heart-toggle button — T0023, schema doesn't exist.
- Search pill wiring beyond whatever already existed — T0021.
- Nav package-count badge — T0016 scope, not built as a side effect here.

**Verification:**
- `npx tsc --noEmit -p .` clean.
- Dev server restarted clean (killed port 3004, `rm -rf .next`, cold start).
- Playwright, signed in as `darin@altoscope.so`: page loads real product data (233 active
  products across 13 categories); clicking a sidebar category updates the URL
  (`/browse?category=mirrorless-cameras`) and the grid; `/browse?category=lenses&page=2`
  renders page 2; clicked an add-to-package button and confirmed via Neon MCP (project
  `sweet-field-99809899`, branch `br-super-base-am9e7j58`) that a real `package_items` row
  was written for the clicked product ("10 X 20 IS", timestamp matched the click). Full-page
  screenshot taken and visually checked against the Elevation Kit dark theme (surface/02
  cards, mono pricing, 10px-radius sidebar rows, tab underline) before calling this done.
