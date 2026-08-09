import { cn } from "@/lib/utils"

export interface StepDotsProps {
  steps: string[]
  activeIndex: number
  onSelect?: (index: number) => void
  className?: string
}

// Elevation Kit — StepDots: onboarding-flow progress indicator. Inactive dots
// are 8px wide/22% white; the active dot expands to 20px/surface-inverse.
// 250ms width+color transition matches the SegmentedToggle/Switch motion spec.
export function StepDots({ steps, activeIndex, onSelect, className }: StepDotsProps) {
  return (
    <div className={cn("flex h-5 items-center gap-2", className)}>
      {steps.map((label, i) => {
        const active = i === activeIndex
        return (
          <button
            key={label}
            type="button"
            title={label}
            aria-label={label}
            aria-current={active ? "step" : undefined}
            onClick={onSelect ? () => onSelect(i) : undefined}
            style={{
              width: active ? 20 : 8,
              background: active ? "var(--surface-inverse)" : "rgba(255,255,255,0.22)",
            }}
            className={cn(
              "h-1 flex-none rounded-full transition-[width,background-color] duration-[250ms]",
              onSelect && "cursor-pointer"
            )}
          />
        )
      })}
    </div>
  )
}
