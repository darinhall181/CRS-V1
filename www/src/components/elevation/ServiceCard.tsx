import type { ReactNode } from "react"
import { cn } from "@/lib/utils"
import { FOCUS_RING } from "./shared"
import { PhotoWell } from "./PhotoWell"

export interface ServiceCardProps {
  thumb?: ReactNode
  title: string
  count: number | string
  availabilityLabel: string
  onClick?: () => void
  className?: string
}

// Elevation Kit — Card/service: 52px thumb, mono count within a muted caption.
export function ServiceCard({ thumb, title, count, availabilityLabel, onClick, className }: ServiceCardProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "flex items-center gap-[14px] rounded-[14px] bg-[var(--surface-02)] px-4 py-3 text-left shadow-[var(--elevation-1)] transition-colors hover:bg-[var(--surface-02-hover)]",
        FOCUS_RING,
        className
      )}
    >
      <div className="h-[52px] w-[52px] flex-none">
        <PhotoWell radius={10} placeholder={title}>
          {thumb}
        </PhotoWell>
      </div>
      <div className="flex flex-col gap-0.5">
        <span className="text-[13px] font-medium">{title}</span>
        <span className="text-[11px] text-[var(--text-muted)]">
          <span className="font-mono">{count}</span> available {availabilityLabel}
        </span>
      </div>
    </button>
  )
}
