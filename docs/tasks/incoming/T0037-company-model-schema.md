---
title: Company model schema — nullable productions.companyId, companyType, atomic studio creation
status: open
severity: high
type: task
component: www/src/lib/db/schema.ts, www/src/lib/db/queries.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
From the 2026-08-08 "Onboarding, Permissions & Pricing" workshop (decided, section 1–2).
Today `productions.companyId` is `NOT NULL` and nothing distinguishes a rental-house
company from a production-studio company — both block the solo/hobbyist model the
workshop settled on.

- **`productions.companyId` → nullable.** Migration required (currently `NOT NULL` in
  `schema.ts`). Solo/hobbyist productions have no company at all.
- **Add `companies.companyType`** enum (`rental_house` | `production_studio`). Nothing
  currently distinguishes them structurally — `plan` shouldn't do double duty for this.
- **Atomic studio-creation action.** Creating a `companies` row (`createdBy` = user) and
  its `companyMembers` owner row must happen as one transaction, never two steps a user
  can leave half-done — a company with no owner membership row breaks every permission
  check that reads `companyMembers`, including for the person who made it. Same action
  serves both first-time studio creation during onboarding (T0019, exact UI placement
  still open there) and a later solo→studio upgrade from settings — one action, two
  entry points, not two flows.
- **Existing solo productions do NOT auto-migrate** into a newly created company. They
  stay personal (`companyId` null) until the user manually attaches them. Auto
  re-parenting past work into a new paid entity is a trust-eroding surprise — don't do it
  even as a convenience default.

## Progress
- [ ] `productions.companyId` nullable migration
- [ ] `companies.companyType` enum + column
- [ ] Atomic `createCompany` action/query (companies + companyMembers owner row, one
      transaction)
- [ ] Confirm no auto-migration path exists for a user's prior solo productions

## Notes
- Parked, not built: a `companyAffiliations` table for solo→studio credibility/portfolio
  display ("worked on 4 productions with XYZ"). Can be derived from `productionMembers`
  history without a new table. Only worth adding if freelancers need to self-claim an
  affiliation *before* ever being hired — revisit if that need actually shows up.
- Feeds T0019 (onboarding) and any future "upgrade to studio" settings surface.

## Verification
Create a company via the atomic action; confirm both the `companies` row and its owner
`companyMembers` row exist in the same transaction (no window where one exists without the
other). Create a solo production, then create/upgrade to a studio — confirm the prior
production's `companyId` is still null afterward.
