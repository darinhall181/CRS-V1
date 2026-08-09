// Shared constants for the Elevation Kit primitives (T0034 / T0015).
// Usage rule #5: the focus ring is identical on every interactive element —
// 3px rgba(61,85,168,.20) halo + #3D55A8 edge. Centralized here so it can't drift.
export const FOCUS_RING =
  "outline-none focus-visible:ring-[3px] focus-visible:ring-[var(--focus-ring-halo)] " +
  "focus-visible:border-[var(--focus-ring-edge)]"

// Usage rule (segmented toggle motion spec): 250ms cubic-bezier(.3,.9,.3,1).
export const THUMB_EASE = "cubic-bezier(0.3, 0.9, 0.3, 1)"

// T0036 — selected-card treatment: an elevation/1 card gets a 1.5px interactive-hover
// inset ring layered on top when selected. A state, not a new component — apply to
// any card-shaped primitive's className via `cn(..., selected && SELECTED_CARD_RING)`.
export const SELECTED_CARD_RING = "shadow-[var(--elevation-1),inset_0_0_0_1.5px_var(--interactive-hover)]"
