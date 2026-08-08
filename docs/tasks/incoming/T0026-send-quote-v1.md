---
title: Send quote v1 — draft → sent, quote rows created, coordinator-gated
status: open
severity: high
type: task
component: www/src/app/(app)/package-builder/actions.ts, www/src/lib/db/queries.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 3 (Package Builder), 3 of 3. The first half of the core workflow becomes real. The
"Send quote ↗" sunset CTA:

1. Picks target rental house(s) — simple dialog listing `rental_house` rows (map-based
   selection arrives with Batch 4).
2. Transitions the selected package_items `draft → sent` (this finally motivates the
   `updatePackageItemStatus` query T0005 deliberately deferred).
3. Creates `package_item_quote` rows per item × house (`is_available = null` = awaiting
   reply) — the exact workflow documented in schema.ts comments.
4. Writes a `package_event` (T0025).
5. Gated: coordinator/producer only (`getViewerContext`, T0017) — the first real
   role-based UI difference (T0007's example case).

NOT in scope: the RFQ document/page (Batch 6), emails to houses, hold expiry. Status
chips on builder rows should reflect sent/quote_received states (colors per handoff
semantic tokens).

## Verification
Send as coordinator → item statuses and quote rows confirmed by DB read-back; DP-role user
does not see the action; second send does not duplicate quote rows.
