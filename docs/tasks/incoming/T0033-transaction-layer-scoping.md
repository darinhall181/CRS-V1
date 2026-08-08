---
title: Scope the transaction layer — Altoscope hosts the production↔house payment
status: open
severity: medium
type: task
component: docs/, www/src/lib/db/schema.ts (future)
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Post-Batch-6 (scoping only — no build). Scope decision recorded 2026-08-08: Altoscope is
the pre-production surface that talks to rental houses (not their rental-management
system), **and it hosts the monetary transaction between the production studio and the
rental house.** This task turns that into a concrete design before any payment code:

- Flow shape: approved RFQ → invoice (from the rfq's immutable approval snapshot, see
  T0031) → payment (deposit? full? net terms — houses commonly run Net 15/30 per the
  DP-profile account data) → payout to the house, minus Altoscope's take.
- Provider evaluation: Stripe Connect is the obvious candidate (two-business platform,
  destination charges, holds); confirm against deposit/damage-waiver and net-terms
  realities from the rental-house research.
- Schema sketch (build later, separate task): `invoice`, `payment`, `payout` keyed to
  `rfq.id` — never to live package data.
- Open questions to answer: who is merchant of record; how net-terms invoices coexist
  with card payments; refund/dispute path when a line is flagged unavailable after
  approval; whether the damage waiver flows through Altoscope or stays house-direct.

## Notes
Darin mentioned recent test plans / markdown files elsewhere (not on `develop`'s docs/)
that already describe this — pull those in as the starting input when this task starts.
Prerequisite: Batch 6 (T0031/T0032) landed, since the RFQ document is the anchor object.
