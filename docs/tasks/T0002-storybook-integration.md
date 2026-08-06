---
title: Decide on Storybook adoption
status: open
severity: medium
type: task
component: www/
found_by: claude-code
found_date: 2026-08-05
verified_live: false
github_issue: null
---

## Summary
Recommended after the catalog-drawer bug (see T0001 / browser-findings) —
building composed pages one-shot without isolated visual verification is
exactly how that class of bug got in. Storybook would let hand-built
components (drawer, grid rows, detail panel, etc.) get verified in
isolation before being composed into a full page.

## Notes
Not started. Revisit once more role-view pages are being built the same
way `package-builder-client.tsx` was (see T0006).
