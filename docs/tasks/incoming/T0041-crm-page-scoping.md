---
title: CRM page — identify need, not yet scoped
status: open
severity: low
type: improvement
component: www/src/app/(app)/
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Identified as missing during the 2026-08-08 "Onboarding, Permissions & Pricing" workshop —
not scoped there, just flagged as a gap. A studio managing relationships with rental
houses, collaborators, and past productions has nowhere to see that relationship history
today (see T0037's note that solo→studio credibility can be *derived* from
`productionMembers` history — a CRM surface is the natural place that derivation would
actually render).

## Notes
This is a scoping task, not a build task — the first work here is figuring out what a CRM
page actually needs to show (relationship history, contact info, past production
pairings?) before any schema or UI gets designed. Likely relates to `companyAffiliations`
(parked in T0037) if that table ever gets built.
