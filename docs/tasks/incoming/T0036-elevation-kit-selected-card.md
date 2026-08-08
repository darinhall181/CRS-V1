---
title: Add the selected-card treatment to the Elevation Kit primitives
status: open
severity: low
type: task
component: www/src/components/elevation/
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
A second, independent task (`T0034-elevation-primitives-storybook.md`, created without
awareness of the already-finished `docs/tasks/finished/T0034-elevation-kit-primitives.md`
— same primitives, same Storybook setup, near-verbatim scope) collided on the number T0034
and was almost entirely redundant. Renumbered to T0036 and trimmed to the one genuinely new
piece it surfaced: the onboarding handoff (`~/Downloads/handoff_onboarding/`) adds a
selected-card treatment not in the original Elevation Kit primitives spec —
`elevation/1 + inset 0 0 0 1.5px #4D68C0` — used for the onboarding wizard's selectable
option cards (workspace type, profession, etc., per T0019).

- Add this as a variant/prop on the existing card primitives in
  `www/src/components/elevation/` (or a shared `selected` style hook if multiple card
  types need it) rather than a new component — it's a state, not a new primitive.
- Story: unselected vs. selected side by side.

## Notes
Everything else from the original T0034 duplicate (Storybook setup, Button/IconButton/
Chip/SegmentedToggle/SearchPill/StatusBadge/card variants/Timeline/SectionHeader) is
already done — see `docs/tasks/finished/T0034-elevation-kit-primitives.md`. T0016/T0018/
T0019/T0020/T0024 should consume those existing components, not rebuild them.

## Verification
Storybook story shows both states; visually matches `inset 0 0 0 1.5px #4D68C0` on an
elevation/1 card against the onboarding prototype.
