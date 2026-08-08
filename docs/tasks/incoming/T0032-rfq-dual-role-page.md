---
title: RFQ page — one document, two role views
status: open
severity: high
type: task
component: www/src/app/(app)/rfq/
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 6 (RFQ), 2 of 2. Build `Request for Quote.dc.html` as `/rfq/[id]`. The role
determines the view per the handoff's region-by-region table: banner tone, primary actions
(Approve quote / Send revised quote), column 4 (Status vs Inventory), line sub-copy
(client_note vs internal_note), money panel (Budget vs Quote value + margin), side panel,
COI framing, composer target. Line-item ⋯ edit menu (substitute, qty, rate, sub-rental
source, note, flag, remove-with-confirm) is house-side only.

- Role comes from `getViewerContext()` extended with rental-house membership (T0031) —
  production_member → production view, rental_house_member → house view. Keep the
  prototype's segmented role *switch* behind a dev flag for side-by-side review (its
  README says exactly this: the switch is a review tool, not production behavior).
- View split is enforced at the query: the production query never selects internal_note /
  sub_rental_cost / margin inputs. Two query shapes, one page component.
- Approve (production) locks pricing: rfq.status → approved, items → approved, selected
  quotes marked, `day_rate_snapshot` written. Send revised (house): version++, line
  statuses updated, event written. Hold expiry line reads `hold_expires_at`; "Extend hold
  48 hrs" bumps it.
- Thread = rfq_message with side pills; timeline = events feed.

This task closes the loop on the full workflow: browse → build → send → revise → approve →
confirmed. When it lands, T0006/T0007 close too.

## Verification
Two browsers, two accounts (coordinator + seeded house agent): each sees only their view's
columns/actions against the same rfq id; approve/revise round-trip confirmed by DB
read-back and both screens re-rendering correctly.
