---
title: Rework /browse into the Storefront layout (sidebar, tabs, card grid, pagination)
status: open
severity: high
type: task
component: www/src/app/(app)/browse/
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
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
