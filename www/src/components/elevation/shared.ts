// Shared constants for the Elevation Kit primitives (T0034 / T0015).
// Usage rule #5: the focus ring is identical on every interactive element —
// 3px rgba(61,85,168,.20) halo + #3D55A8 edge. Centralized here so it can't drift.
export const FOCUS_RING =
  "outline-none focus-visible:ring-[3px] focus-visible:ring-[var(--focus-ring-halo)] " +
  "focus-visible:border-[var(--focus-ring-edge)]"

// Usage rule (segmented toggle motion spec): 250ms cubic-bezier(.3,.9,.3,1).
export const THUMB_EASE = "cubic-bezier(0.3, 0.9, 0.3, 1)"
