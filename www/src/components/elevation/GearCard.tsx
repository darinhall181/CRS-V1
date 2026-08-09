import type { ReactNode } from "react"
import { Plus } from "lucide-react"
import { cn } from "@/lib/utils"
import { IconButton } from "./IconButton"
import { PhotoWell } from "./PhotoWell"
import { SELECTED_CARD_RING } from "./shared"

export interface GearCardProps {
  photo?: ReactNode
  name: string
  spec: string
  rate: string
  rateUnit?: string
  onAdd?: () => void
  /** T0036 selected-card treatment — elevation/1 + 1.5px interactive-hover inset ring. */
  selected?: boolean
  className?: string
}

// Elevation Kit — Card/gear: surface/02 + elevation/1, 12px radius, 16px padding.
// Photo well 8px radius, object-fit contain. Rate = data/mono 17px/600, unit
// 10px sans muted. Add action = IconButton/square on surface/03. Hover steps
// the container to surface/02-hover; nothing else moves.
export function GearCard({ photo, name, spec, rate, rateUnit = "/day", onAdd, selected, className }: GearCardProps) {
  return (
    <div
      className={cn(
        "flex flex-col gap-1 rounded-[12px] bg-[var(--surface-02)] p-4 shadow-[var(--elevation-1)] transition-colors hover:bg-[var(--surface-02-hover)]",
        selected && SELECTED_CARD_RING,
        className
      )}
    >
      <div className="mb-2.5 h-[143px]">
        <PhotoWell radius={8} placeholder={name}>
          {photo}
        </PhotoWell>
      </div>
      <div className="text-[13px] font-medium">{name}</div>
      <div className="text-[11px] text-[var(--text-muted)]">{spec}</div>
      <div className="mt-2.5 flex items-center justify-between">
        <div className="font-mono text-[17px] font-semibold">
          {rate}
          <span className="text-[10px] font-normal text-[var(--text-muted)]">{rateUnit}</span>
        </div>
        <IconButton
          shape="square"
          icon={<Plus size={14} strokeWidth={2} />}
          aria-label={`Add ${name} to package`}
          onClick={onAdd}
        />
      </div>
    </div>
  )
}
