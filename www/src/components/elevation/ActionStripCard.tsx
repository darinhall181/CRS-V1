import type { ReactNode } from "react"
import { ChevronRight } from "lucide-react"
import { cn } from "@/lib/utils"
import { FOCUS_RING } from "./shared"

export interface ActionStripCardProps {
  icon: ReactNode
  title: string
  subtitle: string
  onClick?: () => void
  className?: string
}

// Elevation Kit — Card/action-strip: icon well on surface/01, trailing
// IconButton/circle on surface/03, whole card is the hit target.
export function ActionStripCard({ icon, title, subtitle, onClick, className }: ActionStripCardProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "flex w-full items-center gap-4 rounded-[16px] bg-[var(--surface-02)] px-5 py-[18px] text-left shadow-[var(--elevation-1)] transition-colors hover:bg-[var(--surface-02-hover)]",
        FOCUS_RING,
        className
      )}
    >
      <div className="flex h-11 w-11 flex-none items-center justify-center rounded-[10px] bg-[var(--surface-01)] text-[var(--text-secondary)]">
        {icon}
      </div>
      <div className="flex flex-1 flex-col gap-0.5">
        <span className="text-sm font-medium">{title}</span>
        <span className="text-xs text-[var(--text-muted)]">{subtitle}</span>
      </div>
      <div className="flex h-9 w-9 flex-none items-center justify-center rounded-full bg-[var(--surface-03)] shadow-[var(--elevation-small)]">
        <ChevronRight size={13} strokeWidth={2.2} />
      </div>
    </button>
  )
}
