---
title: Catalog drawer renders with a transparent background
status: in-progress
severity: high
type: bug
component: www/src/app/(app)/package-builder/package-builder-client.tsx
found_by: claude-browser
found_date: 2026-08-05
verified_live: true
github_issue: "#9"
---

## Summary
The "+" add-gear catalog Sheet renders with no panel background, so the
package grid underneath shows through the drawer, producing an
overlapping/torn look.

## How it was found
Claude ran `bun dev`, opened `/package-builder` in Chrome, and clicked the
add-gear button. The drawer visually showed grid content bleeding through.
Claude then read the compiled module for `package-builder-client.tsx` out of
the webpack module cache (`window.webpackChunk_N_E`) via the browser console
and located the `SheetContent` usage, then confirmed `--bg-base` is
undefined by checking `getComputedStyle(document.documentElement)` and
dumping all `:root` custom properties.

## Root cause
`SheetContent` is given `style={{ background: "var(--bg-base)" }}`.
`--bg-base` does not exist anywhere in the stylesheet (real tokens are
`--background`, `--bg-overlay`, `--bg-sidebar-alt`). The invalid inline
style overrides the component's default `bg-background` class and resolves
to transparent.

Confirmed by claude-code: this wasn't isolated to the Sheet — `--bg-base`,
`--bg-surface`, `--text-primary`, `--text-muted`, `--border-subtle`,
`--border-default`, and `--interactive-default` were all used throughout
`package-builder-client.tsx` (~60 call sites total) without being defined in
`globals.css`. The file was built against the full Figma design-token naming
convention, but only the tokens that didn't already have a shadcn equivalent
(bg-overlay, text-secondary, semantic-*, status-*, etc.) were ever added —
the ones that duplicated an existing shadcn name under a different label
(background→bg-base, foreground→text-primary, etc.) were missed.

## Suggested fix
~~Change `var(--bg-base)` to `var(--background)`, or remove the inline
`style` prop entirely since `SheetContent` already applies `bg-background`.~~
Superseded — fixed at the token layer instead of the ~60 call sites: added
`--bg-base`, `--bg-surface`, `--text-primary`, `--text-muted`,
`--border-subtle`, `--border-default`, `--interactive-default` to
`globals.css` as aliases onto the existing shadcn tokens, so all existing
call sites resolve correctly without being touched individually.

## Repro steps
1. `bun dev`, open `/package-builder`
2. Click the "+" add-gear button
3. Observe grid rows visible through the drawer panel

## Status
Fix applied 2026-08-05 by claude-code (see `globals.css`). **Not yet
re-verified live** — claude-code has no browser access in this session.
Confirmed only that the CSS variable chain resolves correctly by inspection
and that the dev server builds clean. Needs an actual look in a browser
before this moves to `status: fixed`. GitHub issue #9 reopened for the same
reason — see issue comments for the full trail.
