---
title: History/transaction tracking page — identify need, not yet scoped
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
not scoped there, just flagged as a gap, alongside T0041 (CRM). Likely pairs naturally
with the $0-cut hosted-payments feature (see `post-mvp-on-platform-payments.md` and
T0033 — transaction layer scoping): payment history, approval trail, a place to see what
happened across productions/quotes over time.

## Notes
Scoping task, not a build task. Don't start schema/UI work until T0033's transaction layer
shape is settled — this page's data model likely depends on it.
