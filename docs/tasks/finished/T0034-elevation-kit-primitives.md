---
title: Build the Elevation Kit primitives as shared components
status: done
severity: high
type: task
component: www/src/components/elevation/, www/.storybook/, www/src/app/globals.css
found_by: claude-code
found_date: 2026-08-08
completed_date: 2026-08-08
verified_live: false
github_issue: null
---

## Summary
Depends on **T0015** (elevation design tokens) — which was still `open` with no tokens
actually landed in `globals.css` when this task started, so completing T0015's token
system was a prerequisite done as part of this work (see `www/src/app/globals.css`,
the "Elevation Kit" block, and the reconciliation note added to `docs/brand.md`).

Built every primitive from `Elevated Dark Surfaces New Primitives.dc.html` (sections
01–04) in `~/Downloads/design_handoff_altoscope_screens/`, as shared components under
`www/src/components/elevation/` — **not** in `components/ui/` (shadcn primitives
untouched):

- `Button` (primary / accent / raised / ghost)
- `IconButton` (circle 40px "pager" tone, square 34px "control" tone, disabled)
- `Chip` (default / selected / disabled)
- `SegmentedToggle` (300×44 track, 146px thumb, 250ms `cubic-bezier(.3,.9,.3,1)` slide)
- `SearchPill` (segmented, 38px circular submit)
- `StatusBadge` (dot-only for table/line-item cells, pill for header badges)
- `PhotoWell` (shared placeholder — not a port of the prototype's `<image-slot>`,
  which is prototype runtime only per the handoff README)
- Cards: `BookingSummaryCard`, `ActionStripCard`, `ServiceCard`, `GearCard`
- `TimelineRow`, `SectionHeader` (with pager)

All components consume only the new CSS variables (`var(--surface-02)`,
`var(--elevation-1)`, etc.) — zero raw hex in any component file. Shared
`FOCUS_RING` constant in `elevation/shared.ts` enforces usage rule #5 (identical
focus ring everywhere) from one place instead of repeating the class string per
component.

Storybook scaffolded in an earlier session (`www/.storybook/`, `@storybook/nextjs-vite`)
now has its first real stories — one file per primitive, showing all variants plus
hover/focus/disabled states via Tailwind's `hover:`/`focus-visible:`/`disabled:`
variants on the arbitrary-value token classes (no manual JS state needed for hover,
matching how the prototype's `style-hover` attribute behaves). `preview.tsx` imports
`globals.css` so stories render on the real dark canvas (`--surface-00` / `#18181A`),
not an unstyled white page.

## Notes
- **2026-08-08, numbering collision:** a second task was independently created at this
  same number (`T0034-elevation-primitives-storybook.md`, unaware this file already
  existed and was done) with near-identical scope. Renumbered to
  `docs/tasks/incoming/T0036-elevation-kit-selected-card.md` and trimmed to the one
  genuinely new piece it surfaced — a selected-card treatment from a newer onboarding
  handoff, not in this file's original scope.
- **Bugs caught and fixed before calling this done:** this project's Tailwind theme
  *overrides* `rounded-lg`/`rounded-xl` to non-default pixel values (`--radius-lg:
  10px`, `--radius-xl: 14px`, via `@theme inline` aliasing `--radius: 0.625rem`) —
  not Tailwind's stock 8px/12px. Using those semantic class names for `Button`,
  `IconButton` (square), and `GearCard` silently produced the wrong radius (10px/14px
  instead of the spec's 8px/8px/12px). Fixed by using explicit `rounded-[8px]` /
  `rounded-[12px]` instead of relying on theme-aliased utility names — also converted
  the two correct-by-coincidence `rounded-2xl` usages (Booking/ActionStrip cards,
  16px, not touched by the theme override) to explicit pixels too, so nothing here
  depends on an assumption about which radius names are and aren't overridden.
- **Verification gap, flagged not hidden:** no browser/screenshot tool was available
  in this environment, so the "check each story against the open prototype side by
  side" step in this task's brief was only done as a careful line-by-line numeric
  audit of every component's spacing/radius/font-size against the prototype's inline
  styles (see the bug above — that audit is what caught it), not true pixel
  comparison. `bun run storybook` (now pinned to port **6007**, not Storybook's
  default 6006, after a collision with another local project) — open it alongside
  the `.dc.html` file yourself for the final visual pass before `verified_live` flips
  to true.
- `StatusBadge`'s tone triads (`--success-dot/-text/-fill` etc.) are new tokens,
  additive to the existing `--semantic-*` and `--status-*` tokens already relied on
  by the Package Builder's status pills — nothing existing was touched or renamed.
- **T0016/T0018/T0020/T0024 must consume these components instead of rebuilding
  them.** In particular T0024 (Package Builder elevation restyle) is the most direct
  beneficiary — `package-builder-client.tsx`'s inline `DetailPanel`/`BudgetPanel`/
  `Row`/`Cell` local functions (see T0002's original motivation) are exactly the kind
  of hand-built pieces this kit should replace, not sit alongside.
