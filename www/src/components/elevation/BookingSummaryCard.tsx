import type { ReactNode } from "react"
import { cn } from "@/lib/utils"
import { Button } from "./Button"
import { PhotoWell } from "./PhotoWell"

export interface BookingSummaryCardProps {
  photo?: ReactNode
  title: string
  subtitle: string
  dateLabel: string
  rate: string
  rateUnit?: string
  address: string
  actionLabel: string
  onAction?: () => void
  className?: string
}

// Elevation Kit — Card/booking-summary: surface/02 + elevation/1, 16px radius,
// image well 10px radius, footer separated by a 1px white-8% divider,
// action = Button/raised.
export function BookingSummaryCard({
  photo,
  title,
  subtitle,
  dateLabel,
  rate,
  rateUnit = "/day",
  address,
  actionLabel,
  onAction,
  className,
}: BookingSummaryCardProps) {
  return (
    <div
      className={cn(
        "overflow-hidden rounded-[16px] bg-[var(--surface-02)] shadow-[var(--elevation-1)]",
        className
      )}
    >
      <div className="grid grid-cols-[108px_1fr] gap-[18px] p-[18px]">
        <div className="h-[108px]">
          <PhotoWell radius={10} placeholder="Rental house photo">
            {photo}
          </PhotoWell>
        </div>
        <div className="flex flex-col gap-1">
          <span className="text-[16px] font-medium">{title}</span>
          <span className="text-xs text-[var(--text-secondary)]">{subtitle}</span>
          <span className="mt-2 text-xs text-[var(--text-muted)]">{dateLabel}</span>
          <span className="mt-auto font-mono text-sm font-semibold">
            {rate}
            <span className="font-sans text-[10px] font-normal text-[var(--text-muted)]"> {rateUnit}</span>
          </span>
        </div>
      </div>
      <div
        style={{ boxShadow: "0 -1px 0 var(--elevation-divider)" }}
        className="flex items-center justify-between gap-4 px-[18px] py-[14px]"
      >
        <span className="text-xs leading-relaxed text-[var(--text-secondary)]">{address}</span>
        <Button variant="raised" className="h-[34px] flex-none px-4 text-xs" onClick={onAction}>
          {actionLabel}
        </Button>
      </div>
    </div>
  )
}
