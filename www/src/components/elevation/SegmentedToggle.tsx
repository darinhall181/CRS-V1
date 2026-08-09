import { useId } from "react"
import { cn } from "@/lib/utils"
import { FOCUS_RING, THUMB_EASE } from "./shared"

export interface SegmentedToggleProps {
  options: readonly string[]
  value: number
  onChange: (value: number) => void
  width?: number
  height?: number
  className?: string
  "aria-label"?: string
}

// Elevation Kit — SegmentedToggle: track surface/01 + elevation/-1 (inset),
// thumb surface/inverse + elevation/2, 250ms cubic-bezier(.3,.9,.3,1) slide.
// The active option's label sits on the white thumb, so it inverts to
// surface/00 (dark) while inactive labels stay text-muted. N-option (2-way
// sensor-format toggle, 3-way onboarding experience-level picker, etc.) —
// the thumb width/position is derived from options.length, not hardcoded.
export function SegmentedToggle({
  options,
  value,
  onChange,
  width = 300,
  height = 44,
  className,
  "aria-label": ariaLabel,
}: SegmentedToggleProps) {
  const inset = 4
  const count = options.length
  const thumbWidth = (width - inset * 2) / count
  const thumbLeft = inset + value * thumbWidth
  const id = useId()

  return (
    <div
      role="radiogroup"
      aria-label={ariaLabel}
      style={{ width, height, borderRadius: height / 2 }}
      className={cn(
        "relative select-none bg-[var(--surface-01)] shadow-[var(--elevation-inset)]",
        className
      )}
    >
      <div
        aria-hidden
        style={{
          top: inset,
          bottom: inset,
          width: thumbWidth,
          left: thumbLeft,
          borderRadius: (height - inset * 2) / 2,
          transition: `left 250ms ${THUMB_EASE}`,
        }}
        className="absolute bg-[var(--surface-inverse)] shadow-[var(--elevation-2)]"
      />
      <div className="absolute inset-0 grid" style={{ gridTemplateColumns: `repeat(${count}, 1fr)` }}>
        {options.map((label, i) => {
          const active = value === i
          return (
            <button
              key={`${id}-${i}`}
              type="button"
              role="radio"
              aria-checked={active}
              onClick={() => onChange(i)}
              style={{ color: active ? "var(--surface-00)" : "var(--text-muted)" }}
              className={cn(
                "flex items-center justify-center rounded-[inherit] text-[13px] font-medium transition-colors duration-[250ms]",
                FOCUS_RING
              )}
            >
              {label}
            </button>
          )
        })}
      </div>
    </div>
  )
}
