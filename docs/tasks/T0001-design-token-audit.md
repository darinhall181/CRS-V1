---
title: Design token audit — Figma token names vs. globals.css
status: done
severity: high
type: task
component: www/src/app/globals.css
found_by: claude-code
found_date: 2026-08-05
verified_live: false
github_issue: "#9"
---

## Summary
`package-builder-client.tsx` was built using the Figma design-system's token
names directly (`--bg-base`, `--text-primary`, `--interactive-default`,
etc.), assuming they existed in `globals.css`. 7 of them didn't — only the
shadcn semantic names (`--background`, `--foreground`, `--primary`, etc.)
were defined. ~60 call sites across the file silently resolved to
transparent/unset. Full investigation trail in
`docs/browser-findings/2026-08-05-catalog-drawer-transparent-background.md`.

## Fix
Added the missing tokens to `globals.css` as aliases onto the existing
shadcn tokens (`--bg-base: var(--background)`, etc.) rather than touching
every call site individually.

## Notes
This is a fixed instance, not a closed risk class — any future component
built against the Figma token names needs the same check before assuming a
name exists in `globals.css`. Worth a quick grep-and-diff pass
(`var(--x)` usages vs. defined `--x` custom properties) whenever a new
page/component lands, the way it was done here.
