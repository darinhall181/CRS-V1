---
title: Role taxonomy — expand productionRoleEnum vs. userSpecializations join table
status: blocked
severity: medium
type: task
component: www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
From the 2026-08-08 workshop, section 2 — flagged as an open decision, not yet made.
`productionRoleEnum` (dp/coordinator/producer/gaffer) is both too narrow (no DIT,
technician, director, photographer, videographer, etc.) and too rigid (one role per
person; real crew wear multiple hats over time, and often different ones on different
jobs). Two options on the table:

1. **Expand the enum.** Simple, but every new role needs a migration — a bad fit for what
   is, in practice, an open-ended list.
2. **Add a `userSpecializations` join table** (`userId`, `role`) capturing a person's
   general skillset, while `productionMembers.role` stays "what they were on *this* job"
   — can legitimately differ from their default/specialization.

## Blocked on
An explicit decision from Darin on which approach to take — not something to default into
during implementation of a downstream task. Whichever direction, `production_role` stays
the *authorization* enum (per T0035's design notes) — this task is about *display/
discovery* taxonomy, a separate concern already kept separate once (T0035 explicitly did
not widen `production_role` for the onboarding `profession` field, for the same reason).

## Notes
Affects anywhere role labels are shown for discovery/filtering (profile pages, crew
listings) — currently profile bio/metadata handles this informally; this task is about
whether that becomes structured.
