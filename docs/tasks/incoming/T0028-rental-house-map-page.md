---
title: Rental House Map page — split results/map view with package-match
status: open
severity: high
type: task
component: www/src/app/(app)/map/
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 4 (Map), 2 of 2. Build `Rental House Map.html` as a real route: fixed header with
shrink-on-scroll, filter chips, 470px scrolling results column, fixed map with price-pill
pins, two-way card↔pin selection.

- Server component fetches houses + locations + (when a package id is in scope) the
  package-match computation: % of current package_items with a matching
  `rental_house_inventory` row at that house → full (`#8FBF9F`) / partial (`#D9B36A`)
  match line, min-total price pill. This is pure query work — no schema change.
- Map library: prototype uses Leaflet; recommend **MapLibre GL** (free, vector tiles,
  proper dark styles instead of the CSS-filter hack). Either is acceptable — keep the
  dark treatment, price-pill pins, preserved attribution.
- Map is a client component fed serialized props; selection state stays client-side.
- Search pill segments (gear / dates / house) can be display-only in v1 except house-name
  filtering; date-based availability is out of scope (no booking data exists — planning
  surface, per the plan doc's guardrail #5).

## Notes
Depends on T0027. Entry point: "find houses for this package" from the builder, plus nav.
