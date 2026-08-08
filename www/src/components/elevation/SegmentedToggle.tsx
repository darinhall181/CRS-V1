import { useId } from "react"
import { cn } from "@/lib/utils"
import { FOCUS_RING, THUMB_EASE } from "./shared"

export interface SegmentedToggleProps {
  options: readonly [string, string]
  value: 0 | 1
  onChange: (value: 0 | 1) => void
  width?: number
  height?: number
  className?: string
  "aria-label"?: string
}

// Elevation Kit — SegmentedToggle: track surface/01 + elevation/-1 (inset),
// thumb surface/inverse + elevation/2, 250ms cubic-bezier(.3,.9,.3,1) slide.
// The active option's label sits on the white thumb, so it inverts to
// surface/00 (dark) while the inactive label stays text-muted.
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
  const thumbWidth = (width - inset * 2) / 2
  const thumbLeft = value === 0 ? inset : width - inset - thumbWidth
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
      <div className="absolute inset-0 grid grid-cols-2">
        {options.map((label, i) => {
          const active = value === i
          return (
            <button
              key={`${id}-${i}`}
              type="button"
              role="radio"
              aria-checked={active}
              onClick={() => onChange(i as 0 | 1)}
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
