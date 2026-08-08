---
title: Geo columns on rental_house_location + seed the 14 Ohio houses
status: open
severity: medium
type: task
component: www/src/lib/db/schema.ts, db seed
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 4 (Map), 1 of 2. `rental_house_location` has address text but no coordinates — the
map has nothing to plot.

- Migration: `latitude double precision`, `longitude double precision` on
  `rental_house_location`. Plain columns, not PostGIS — pin-plotting and
  distance-sorting at this scale don't justify the extension; revisit only if real
  geo-search arrives.
- Seed from `ohio_rental_houses.csv` (14 real houses: Cleveland/Columbus/Cincinnati/
  Akron/Kent tier — the mid-size regional tier the inventory workbook models):
  `rental_house` + `rental_house_location` rows, `type` mapped from the analysis doc
  (full_service vs specialty), contact emails where present. Geocode addresses once at
  seed time (any free geocoder; hand-fix stragglers — it's 14 rows).
- Optionally attach a few `rental_house_inventory` rows to 2–3 houses (rates from the
  workbook's Rate Card tab) so package-match (T0028) has something to chew on.

## Verification
Joined read-back: 14 houses, each with ≥1 location carrying non-null lat/lng inside Ohio's
bounding box.
