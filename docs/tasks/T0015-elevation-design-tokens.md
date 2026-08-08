---
title: Add the elevation design tokens (surface ramp + shadow ramp) to globals.css
status: done
severity: high
type: task
component: www/src/app/globals.css, docs/brand.md
found_by: claude-code
found_date: 2026-08-08
verified_live: false
github_issue: null
---

**Done 2026-08-08**, as a prerequisite of T0034 (Elevation Kit primitives) — the
primitives can't consume tokens that don't exist yet, so this landed first in the
same pass rather than as a separate task. Full surface ramp, elevation ramp,
semantic tint triads (additive — existing `--semantic-*`/`--status-*` tokens
untouched), divider/hover alphas, and focus ring vars are in `globals.css`.
`docs/brand.md` updated with an "Elevation" section reconciling the border-only
language with the new shadow-based system, per this task's own note below.

## Summary
Batch 0 (Foundations), 3 of 5. All five redesigned screens consume one token system —
the "Elevated Dark Surfaces" language from the design handoffs
(`design_handoff_altoscope_screens/README.md` is the spec; read its Design Tokens section
first). Land it once as CSS variables in `globals.css` so no screen ever inlines hex values
from the prototypes:

- Surface ramp: base `#18181A`, page shell `#101012`, surface/01 `#2E2E34` … surface/03
  `#45454E`, menu/pager/inverse/disabled variants.
- Elevation ramp (pure black, never tinted): elevation/1, 1-hero, 2, menu, small, -1 inset.
- Semantic: interactive `#3D55A8`/`#4D68C0`, accent sunset `#FFCF7B` (one CTA per screen),
  success/warning/info/danger tints, divider/hover alphas.
- Focus ring: 3px `rgba(61,85,168,.20)` halo + `#3D55A8` edge — identical everywhere.

Reconcile the deliberate contradiction: `docs/brand.md` says "borders over shadows"; the
handoff inverts that for the whole app pass. Update brand.md in the same commit rather than
leaving two truths.

## Notes
Typeface: prototypes use Aktiv Grotesk trial fonts — a licensing decision, not a token one.
Keep the current app font wired via `--font-sans` until a license call is made; the token
layer makes the swap one line later. Mono stack is for numeric/code values only (rates,
SKUs, totals, timestamps).
