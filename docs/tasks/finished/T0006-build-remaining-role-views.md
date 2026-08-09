---
title: Build the 4 remaining role views as real pages (Producer, Coordinator, Gaffer, Rental House)
status: done
severity: medium
type: task
component: www/src/app/(app)/
found_by: claude-code
found_date: 2026-08-05
completed_date: 2026-08-08
verified_live: false
github_issue: null
---

## Summary
Only the DP view exists as a real Next.js page (`package-builder`). The
other 4 role views exist in the Figma design system
(Altoscope Design System file) but not as real app routes/components yet.

## Notes
`gaffer` now has a schema seat as of 2026-08-05 — `production_role` enum
value + `department` column on `production_members`
(`supabase/migrations/20260805120000_add_gaffer_role.sql`). Consider T0002
(Storybook) before building these, given what happened building the first
one without isolated component verification.

## Summary (2026-08-08) — superseded, closed without building
The 2026-08-08 onboarding/permissions workshop explicitly settled the opposite
direction from this task's premise (see `docs/tasks/incoming/T0040-approval-authority.md`):
**one shared UI experience, not forked by role.** Role labels (DP/gaffer/producer/etc.)
are bio/profile metadata for discovery, not a reason to build separate pages. The only
real UI differentiators that survived that decision are (a) a company-context switcher
(studio members vs. solo — in scope for T0016) and (b) the approval-authority gate
(T0040, still blocked on an explicit rule). Building 4 separate role-view pages as
originally scoped here would have built the wrong thing. Closed rather than built;
`gaffer`'s schema seat (the migration referenced above) is unaffected and stays valid —
this only retires the "separate page per role" UI direction.
