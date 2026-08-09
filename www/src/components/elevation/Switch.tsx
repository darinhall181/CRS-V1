import { cn } from "@/lib/utils"
import { FOCUS_RING, THUMB_EASE } from "./shared"

export interface SwitchProps {
  checked: boolean
  onChange: (checked: boolean) => void
  "aria-label": string
  className?: string
}

// Elevation Kit — Switch: binary on/off, distinct from SegmentedToggle (which
// is a labeled multi-option slider). Track = surface/01 + elevation/inset when
// off, interactive/default when on. Thumb = surface/inverse, 250ms slide.
export function Switch({ checked, onChange, "aria-label": ariaLabel, className }: SwitchProps) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={ariaLabel}
      onClick={() => onChange(!checked)}
      style={{ background: checked ? "var(--interactive-default)" : "var(--surface-01)" }}
      className={cn(
        "relative h-[26px] w-[46px] flex-none rounded-full transition-colors",
        !checked && "shadow-[var(--elevation-inset)]",
        FOCUS_RING,
        className
      )}
    >
      <span
        style={{ left: checked ? 23 : 3, transition: `left 200ms ${THUMB_EASE}` }}
        className="absolute top-[3px] h-5 w-5 rounded-full bg-[var(--surface-inverse)] shadow-[var(--elevation-small)]"
      />
    </button>
  )
}
