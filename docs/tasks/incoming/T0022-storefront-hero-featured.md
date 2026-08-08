---
title: Storefront hero + featured/recommended rows
status: open
severity: low
type: task
component: www/src/app/(app)/gear/
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 2 (Storefront), 3 of 4. The hero (46px display type, one sunset CTA, product photo,
carousel dots) and the "Featured picks" / "Recommended for your package" /
"Prep-day essentials" rows. Content selection:

- v1 heuristic, no schema change: hero = newest flagship camera body with a
  `primary_image_url`; featured = top products by category `importance`/recency with
  images. Recommended-for-your-package can use `product_relationship`
  (requires/recommends) against current package items — the table exists and is exactly
  this feature; seed a handful of rows if empty.
- If curation is wanted later, add a tiny `is_featured` flag — decide then, not now.

## Notes
Product photography: many rows have `primary_image_url` from the pipeline; hero should
gracefully skip products without images. The one-sunset-CTA-per-screen rule applies —
hero "Reserve now" is it; nothing else on the page uses sunset.
