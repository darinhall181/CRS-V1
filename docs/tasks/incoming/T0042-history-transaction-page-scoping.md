---
title: History page — unified transaction/activity ledger
status: open
severity: medium
type: task
component: www/src/app/(app)/history/, www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Now scoped — a real prototype landed (`History.dc.html` in `~/Downloads/Altoscope Gear
Storefront Redesign (3)/`), superseding this task's original "not yet scoped" state. Still
**blocked on T0033** (transaction layer scoping) — this page is the read surface over
whatever T0033 decides the transaction data model actually is, so don't build the schema
here twice.

**One page, two audiences** (role-symmetric, like T0041): production view shows spend
across rental houses, rental view shows revenue across clients — same shape.

**Header:** title + subtitle, date-range cycler (Last 90 days / Last 30 days / This year /
All time), "Export CSV" button. Four stat cards (spend-or-revenue last 90d, outstanding/
receivable amount, open quotes count + value, units/rentals in progress).

**Filters:** type chips with live counts (All / Quotes / Invoices / Payments / Rentals /
Damages — Rentals groups pickup+return, Invoices groups invoice+credit), an "open items
only" toggle, search.

**Table** (sortable by Date and Amount, click header to toggle): Date, Reference (mono
id), Type (icon + label), Party (rental house or client), Production, Amount (mono,
red if overdue), Status (colored pill). Row click expands **inline** (not a drawer) to
show: a 4-fact grid (context-dependent per type — sent-by/contact/rental-period/expires
for a quote; terms/due/contact/PO for an invoice; etc.), a line-items list (item/qty/
amount), and a right-side panel with a timeline (dot + text + mono time) and two buttons
("Open record" + "PDF").

**The record shape driving all of this** — one polymorphic record type spanning 7 kinds:
`quote | invoice | payment | pickup | return | damage | credit`, each carrying: date,
reference, party, production, amount, status, a small facts array, a line-items array, and
a timeline array. This is concrete input for T0033's scoping, not just a UI wish list —
whatever transaction schema T0033 lands on needs to be able to produce exactly this shape
(or this page needs a mapping layer that assembles it from several tables).

## Progress
- [ ] Confirm T0033's transaction schema can produce (or be mapped to) the 7-kind record
      shape above before starting UI work
- [ ] Header: date-range cycler, CSV export, stat cards
- [ ] Filters: type chips with live counts, open-items-only toggle, search
- [ ] Table: sortable columns, inline row expansion (facts/lines/timeline/actions)
- [ ] Role-symmetric behavior verified for both workspace types

## Notes
Status→color mapping in the mockup is granular (Paid/Accepted/Complete = confirmed-green,
Sent/Scheduled = sent-blue, Declined/Overdue = overbudget-red, Expired/Issued = draft-
muted, Outstanding = quotereceived, Assessed = approved-bg + sunset-text) — reuse the
existing `--status-*` tokens already in `globals.css`/T0034 rather than inventing new
ones; they already cover this range.

Pairs with T0031 (quote-document layer feeds the quote/invoice rows) and the $0-cut
hosted-payments feature (payment/payout rows) referenced in
`docs/frontend-backend-plan.md`'s Open Decisions section.

## Verification
Both workspace types render correctly; date-range and type filters actually narrow the
row set (not just visually — confirm the stat cards and CSV export respect the active
filter too); an expanded row's line items sum to its header amount.
