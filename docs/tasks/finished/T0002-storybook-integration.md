---
title: Decide on Storybook adoption
status: done
severity: medium
type: task
component: www/
found_by: claude-code
found_date: 2026-08-05
completed_date: 2026-08-08
verified_live: true
github_issue: null
---

## Summary
Recommended after the catalog-drawer bug (see T0001 / browser-findings) —
building composed pages one-shot without isolated visual verification is
exactly how that class of bug got in. Storybook would let hand-built
components (drawer, grid rows, detail panel, etc.) get verified in
isolation before being composed into a full page.

**Decided and done, 2026-08-08:** adopted. `@storybook/nextjs-vite` scaffolded in
`www/.storybook/`, Tailwind wired via a `globals.css` import in `preview.tsx`. Pinned
to port 6007 (`bun run storybook`) rather than the 6006 default, after colliding with
another local project's Storybook instance. First real stories landed with T0034
(Elevation Kit primitives) — see that file for the component list.

## Notes
Revisited once real hand-built components existed to write stories against —
the Elevation Kit primitives (T0034), not `package-builder-client.tsx`'s inline
sub-components directly (those are slated to be replaced by the kit per T0034's
notes, not storied as-is).
