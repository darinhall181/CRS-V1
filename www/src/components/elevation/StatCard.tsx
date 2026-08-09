import type { ReactNode } from "react"
import { cn } from "@/lib/utils"

export type StatCardTone = "default" | "success" | "warning" | "danger" | "info"

const TONE_COLOR: Record<StatCardTone, string> = {
  default: "var(--text-primary)",
  success: "var(--success-text)",
  warning: "var(--warning-text)",
  danger: "var(--status-overbudget-text)",
  info: "var(--info-text)",
}

export interface StatCardProps {
  label: string
  value: ReactNode
  unit?: string
  note?: string
  tone?: StatCardTone
  className?: string
}

// Elevation Kit — StatCard: Card/16px radius + elevation/1, uppercase 11px
// muted label, mono data value (tone drives value color only), 11.5px note.
// Used in 4-up grids (Dashboard, History headers).
export function StatCard({ label, value, unit, note, tone = "default", className }: StatCardProps) {
  return (
    <div
      className={cn(
        "flex flex-col gap-2.5 rounded-[14px] bg-[var(--surface-02)] p-[18px] shadow-[var(--elevation-1)]",
        className
      )}
    >
      <span className="text-[11px] font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]">
        {label}
      </span>
      <div className="flex items-baseline gap-[7px]">
        <span
          style={{ color: TONE_COLOR[tone] }}
          className="font-mono text-[26px] font-medium leading-none tracking-[-0.02em]"
        >
          {value}
        </span>
        {unit && <span className="text-xs text-[var(--text-muted)]">{unit}</span>}
      </div>
      {note && <span className="text-[11.5px] leading-[1.45] text-[var(--text-secondary)]">{note}</span>}
    </div>
  )
}
