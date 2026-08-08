import { Search } from "lucide-react"
import { cn } from "@/lib/utils"
import { FOCUS_RING } from "./shared"

export interface SearchPillSegment {
  label: string
  value: string
  /** Render value in text-subtle (empty/placeholder state), e.g. "Any". */
  placeholder?: boolean
}

export interface SearchPillProps {
  segments: SearchPillSegment[]
  onSubmit?: () => void
  className?: string
}

// Elevation Kit — SearchPill: surface/01 + elevation/2, segment dividers are a
// 1px white-8% inset (box-shadow, not a layout border), label = uppercase
// text/label 10px, empty value = text-subtle, submit = 38px circular blue.
export function SearchPill({ segments, onSubmit, className }: SearchPillProps) {
  return (
    <div
      className={cn(
        "flex items-center rounded-full bg-[var(--surface-01)] shadow-[var(--elevation-2)]",
        className
      )}
    >
      {segments.map((segment, i) => (
        <div
          key={segment.label}
          style={i > 0 ? { boxShadow: "-1px 0 0 var(--elevation-divider)" } : undefined}
          className="flex flex-col gap-0.5 px-[22px] py-[10px]"
        >
          <span className="text-[10px] font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]">
            {segment.label}
          </span>
          <span
            className={cn(
              "text-[13px] font-medium",
              segment.placeholder ? "text-[var(--text-subtle)] font-normal" : "text-[var(--text-primary)]"
            )}
          >
            {segment.value}
          </span>
        </div>
      ))}
      <button
        type="button"
        aria-label="Search"
        onClick={onSubmit}
        style={{ width: 38, height: 38 }}
        className={cn(
          "mr-1.5 ml-1 flex flex-none cursor-pointer items-center justify-center rounded-full border-none bg-[var(--interactive-default)] text-white transition-colors hover:bg-[var(--interactive-hover)]",
          FOCUS_RING
        )}
      >
        <Search size={14} strokeWidth={2.4} />
      </button>
    </div>
  )
}
