---
title: App shell v2 — global nav + shared (app) layout per the design handoffs
status: open
severity: medium
type: task
component: www/src/components/nav/, www/src/app/(app)/layout.tsx
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 0 (Foundations), 4 of 5. Replace the current light shadcn navbar with the handoff's
flat global nav (72px, base surface, no border/shadow): logo mark + wordmark left, centered
underline tabs (Browse · Packages · Quote), account cluster right ("Hello, {name}" +
Account & projects dropdown). The Storefront variant adds the centered search pill and the
package-count badge (count of current package's items — real query, not a prop).

One shared `(app)/layout.tsx` owns the shell so the five screens only render their body.
Account dropdown holds sign-out, saved items (T0023 entry point), and later profile link.

## Notes
Depends on T0015 (tokens). The Rental House Map screen has its own shrinking-header
variant — that stays local to the map page (T0028), not in the shared shell.
