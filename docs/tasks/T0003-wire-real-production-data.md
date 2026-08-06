---
title: Replace hardcoded SHOOT_DAYS/APPROVED_BUDGET with real production data
status: done
severity: medium
type: task
component: www/src/app/(app)/package-builder/
found_by: claude-code
found_date: 2026-08-05
verified_live: false
github_issue: null
---

## Summary
`package-builder-client.tsx` currently hardcodes `SHOOT_DAYS = 18` and
`APPROVED_BUDGET = 105_880`. The `productions` table already has
`shootDays`/`totalBudget` columns. Needs a `getProduction(id)` query in
`lib/db/queries.ts` and wiring through `page.tsx` instead of the constants.

## Done
- Added `getProduction(id)` and `getPackageByProduction(productionId)` to
  `lib/db/queries.ts`
- `page.tsx` fetches both (hardcoded to `DEMO_PRODUCTION_ID` — the seeded
  Top Gun Maverick row — since there's no production-selection/routing yet)
  and passes `productionName`, `packageName`, `shootDays`, `approvedBudget`
  down as props
- Removed the module-level `SHOOT_DAYS`/`APPROVED_BUDGET` constants and the
  hardcoded "Top Gun Maverick — Camera Package" title string from
  `package-builder-client.tsx` entirely — every usage (top bar, budget bar,
  footer total, `BudgetPanel`) now reads from props
- Verified via rendered HTML: real values (`shootDays: 18`,
  `approvedBudget: 105880`, real production/package names) are flowing
  through the actual query chain, not string literals. Not browser-verified
  visually — no UI-visible symptom risk here since the values are
  numerically identical to the old hardcoded ones, just sourced correctly
  now.

## Notes
`DEMO_PRODUCTION_ID` in `page.tsx` is a known temporary shim — real
production selection is a separate, bigger feature not yet scoped.
