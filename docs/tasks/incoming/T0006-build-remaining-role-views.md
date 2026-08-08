---
title: Build the 4 remaining role views as real pages (Producer, Coordinator, Gaffer, Rental House)
status: open
severity: medium
type: task
component: www/src/app/(app)/
found_by: claude-code
found_date: 2026-08-05
completed_date: null
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
