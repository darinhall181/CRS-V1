---
title: Restyle Package Builder to the Elevation spec (drawer catalog, bulk bar, full-width chrome)
status: open
severity: high
type: task
component: www/src/app/(app)/package-builder/
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 3 (Package Builder), 1 of 3. The builder's data wiring is done (T0003/T0005) — this
is a visual + interaction rework to `Package Builder - Elevation.dc.html` (its README is
the most precise spec in the bundle; the prototype's script block documents the exact
derived-value math):

- Remove the persistent category rail → single **Add gear** pill opening the full-height
  catalog drawer (486px, scrim below nav, stays open for a run of adds, esc to close).
- Full-width action toolbar above both columns; full-width totals bar below (v · shoot
  days · house · daily + grand totals, Export CSV slot for T0010).
- Category cards with 44px rows (checkbox / name / SKU / availability / qty / days / rate /
  line total / remove), bulk-action bar on ≥1 checked.
- Context panel: Detail / Budget / Notes segmented tabs. Budget tab: day↔week toggle
  (week = 4× day per the prototype; real `week_rate` from inventory when present wins),
  category bar chart, approved-budget progress vs `productions.total_budget`, over-budget
  notice.
- Keep the existing optimistic add/remove logic exactly as is.

## Notes
Consider landing T0002 (Storybook) first — T0006's note recommends isolated component
verification before the next big build, and this is the next big build. Notes tab renders
against T0025's data; ship the tab disabled/empty if sequencing them apart.
Days-per-line currently equals `shootDays` for every row; a per-line days editor is a
future task, not this one.
