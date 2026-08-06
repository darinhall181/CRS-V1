---
title: SheetOverlay missing forwardRef; DialogContent missing title/description
status: in-progress
severity: low
type: bug
component: www/src/components/ui/sheet.tsx
found_by: claude-browser
found_date: 2026-08-05
verified_live: true
github_issue: "#10"
---

## Summary
Opening the catalog Sheet logs a React ref warning and two Radix
accessibility warnings in the console. Not the cause of the transparency
bug, but worth cleaning up.

## How it was found
Claude read browser console output (`read_console_messages`) while the
drawer was open in a live `bun dev` session.

## Root cause
`SheetOverlay` (sheet.tsx line 36) is a plain function component, not
wrapped in `React.forwardRef`, so Radix's `Slot`/`SlotClone` cannot attach
its ref. Separately, the Sheet's `DialogContent` has no `SheetTitle` /
`SheetDescription`, triggering Radix a11y warnings.

## Suggested fix
Wrap `SheetOverlay` in `React.forwardRef`, and add a `SheetTitle` (can be
visually hidden via the existing VisuallyHidden pattern) plus a
`SheetDescription` to the catalog drawer content.

## Repro steps
1. `bun dev`, open `/package-builder`
2. Open browser console, click the "+" add-gear button
3. See ref warning and two DialogContent a11y warnings

## Status
Fix applied 2026-08-05 by claude-code — wrapped `SheetOverlay` in
`React.forwardRef` in `sheet.tsx`, added a visually-hidden `SheetTitle` +
`SheetDescription` to the catalog drawer in `package-builder-client.tsx`.
**Not yet re-verified live** — no browser access in this session; only
confirmed the dev server builds clean and typecheck passes.
