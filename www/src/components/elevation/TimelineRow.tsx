import { cn } from "@/lib/utils"

export interface TimelineRowProps {
  weekday: string
  day: number | string
  title: string
  subtitle: string
  /** Draw the connector line below the date bubble — omit on the last row. */
  showConnector?: boolean
  className?: string
}

// Elevation Kit — Timeline/row: date bubble on surface/01 with mono digits,
// 1px white-10% connector, event card at Card/14px radius (elevation/1).
export function TimelineRow({ weekday, day, title, subtitle, showConnector = true, className }: TimelineRowProps) {
  return (
    <div className={cn("grid grid-cols-[44px_1fr] gap-x-[14px]", className)}>
      <div className="flex flex-col items-center gap-0.5">
        <span className="text-[10px] text-[var(--text-muted)]">{weekday}</span>
        <span className="flex h-[34px] w-[34px] items-center justify-center rounded-full bg-[var(--surface-01)] font-mono text-xs font-semibold">
          {day}
        </span>
        {showConnector && (
          <span style={{ background: "rgba(255,255,255,0.10)" }} className="min-h-[22px] w-px flex-1" />
        )}
      </div>
      <div
        className={cn(
          "flex items-center gap-[14px] rounded-[14px] bg-[var(--surface-02)] px-[18px] py-[14px] shadow-[var(--elevation-1)]",
          showConnector && "mb-3"
        )}
      >
        <div className="flex flex-col gap-0.5">
          <span className="text-[13px] font-medium">{title}</span>
          <span className="text-[11px] text-[var(--text-muted)]">{subtitle}</span>
        </div>
      </div>
    </div>
  )
}
