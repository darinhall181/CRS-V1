import type { ReactNode } from "react"
import { cn } from "@/lib/utils"

export type StatusTone = "success" | "warning" | "info" | "danger" | "neutral"

const TONE_VARS: Record<StatusTone, { dot: string; text: string; fill: string }> = {
  success: { dot: "var(--success-dot)", text: "var(--success-text)", fill: "var(--success-fill)" },
  warning: { dot: "var(--warning-dot)", text: "var(--warning-text)", fill: "var(--warning-fill)" },
  info: { dot: "var(--info-dot)", text: "var(--info-text)", fill: "var(--info-fill)" },
  danger: { dot: "var(--danger-text)", text: "var(--danger-text)", fill: "rgba(208,140,134,0.14)" },
  neutral: { dot: "var(--text-secondary)", text: "var(--text-secondary)", fill: "var(--neutral-fill)" },
}

export interface StatusBadgeProps {
  tone: StatusTone
  children: ReactNode
  /** "pill" — tinted background + tone-colored text, optional leading icon,
   *  NO dot (DP Profile package-status table, "Verified DP" badge).
   *  "dot" — bare 7px tone-colored dot + neutral text-secondary text, no
   *  background (RFQ line-item status cell, hold-expiry line). */
  variant?: "pill" | "dot"
  icon?: ReactNode
  className?: string
}

// Elevation Kit — StatusBadge, rebuilt against the actual DP Profile / RFQ
// prototype markup (not just the README summary): the pill variant never
// combines a dot with a fill — it's fill+text, or fill+icon+text. Only the
// dot variant carries a literal colored dot, and even then the label text
// itself stays neutral; the dot alone signals tone.
export function StatusBadge({ tone, children, variant = "pill", icon, className }: StatusBadgeProps) {
  const { dot, text, fill } = TONE_VARS[tone]

  if (variant === "dot") {
    return (
      <span className={cn("inline-flex items-center gap-[7px] text-[11px] text-[var(--text-secondary)]", className)}>
        <span style={{ background: dot }} className="h-[7px] w-[7px] flex-none rounded-full" />
        {children}
      </span>
    )
  }

  return (
    <span
      style={{ background: fill, color: text }}
      className={cn(
        "inline-flex h-[22px] items-center gap-[5px] rounded-full text-[11px] font-medium",
        icon ? "pl-[9px] pr-[10px]" : "px-[10px]",
        className
      )}
    >
      {icon}
      {children}
    </span>
  )
}
