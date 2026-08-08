---
title: Free-tier lifetime usage cap — package builder + RFQ, shared counter
status: open
severity: medium
type: task
component: www/src/lib/db/schema.ts, www/src/lib/db/queries.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
From the 2026-08-08 workshop, section 4 (billing model, decided direction — not yet built).

- **Studio/production tier: flat, unlimited once paid.** No per-seat, no per-production
  metering. Pulling a past collaborator into a new production costs nothing to serve and
  should cost the studio nothing extra — per-seat billing here would recreate the
  freelance-churn friction the product exists to remove. Nothing to build for this beyond
  "the cap logic below simply never runs for a paid company."
- **Hobby/free tier: lifetime cap, not monthly.** Figma page-cap pattern (their axis is
  per-seat, Altoscope's is per-account solo/free), used as an upgrade tripwire rather than
  ongoing metering. A monthly reset would reward heavy hobbyist usage indefinitely; a
  lifetime cap is simpler to build (`count(*) where createdBy = user and companyId is
  null`, no rolling window) and a cleaner "you've outgrown free" signal.
- **Cap applies to package builder + RFQ together, as one shared unit** — not two separate
  counters. RFQ is the hero demo moment for the paid workflow product; giving it away
  unlimited on free tier undercuts the paid product. Package builder → RFQ is one funnel
  (build a kit, send for quotes).
- **Browse/database stays open and uncapped for everyone, always** — top-of-funnel, not
  part of the paywalled workflow. Capping it would reduce the database's value as the
  thing that gets people in the door. Nothing to build here either — just don't gate it.
- Once a company has a paid plan, stop checking the cap entirely — it only needs to work
  for the free tier, not forever.

## Progress
- [ ] Shared counter query (package builder + RFQ activity, scoped to `createdBy = user
      and companyId is null`)
- [ ] Cap-check gate on package/RFQ creation actions, free tier only
- [ ] Confirm browse/database queries have no cap check anywhere
- [ ] Confirm cap check is skipped entirely once a company has a paid plan

## Notes
**Not yet finalized (flag for next session):** the exact numeric cap, and whether the unit
should be productions or RFQs/quote-requests sent — productions can stay open a long time
with lots of internal activity, which could make a raw production-count cap feel
arbitrary to a user. Don't pick a number without deciding the unit first.

Depends on T0037 (nullable `companyId` is how "free tier" gets identified — no company =
free/solo).

## Verification
Free-tier account hits the cap after N package-builder/RFQ actions combined (not 2N —
confirms the shared-counter design); a paid company account performs the same actions
past whatever N would be, uncapped; browse/search queries are unaffected regardless of
tier.
