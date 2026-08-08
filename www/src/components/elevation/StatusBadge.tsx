import { cn } from "@/lib/utils"

export type StatusTone = "success" | "warning" | "info" | "danger" | "neutral"

const TONE_VARS: Record<Exclude<StatusTone, "neutral">, { dot: string; text: string; fill: string }> = {
  success: { dot: "var(--success-dot)", text: "var(--success-text)", fill: "var(--success-fill)" },
  warning: { dot: "var(--warning-dot)", text: "var(--warning-text)", fill: "var(--warning-fill)" },
  info: { dot: "var(--info-dot)", text: "var(--info-text)", fill: "var(--info-fill)" },
  danger: { dot: "var(--danger-text)", text: "var(--danger-text)", fill: "rgba(208,140,134,0.14)" },
}

export interface StatusBadgeProps {
  tone: StatusTone
  children: React.ReactNode
  /** "dot" — bare 7px dot + 11px text, for table/line-item status cells (RFQ).
   *  "pill" — dot + text on a tinted rounded-full fill, for header/list badges. */
  variant?: "dot" | "pill"
  className?: string
}

// Elevation Kit — StatusBadge. "dot" matches the RFQ line-item status cell spec
// (7px dot + 11px text); "pill" matches header/verification badges. Neutral tone
// falls back to text-muted for statuses with no strong semantic (e.g. draft).
export function StatusBadge({ tone, children, variant = "pill", className }: StatusBadgeProps) {
  if (tone === "neutral") {
    return (
      <span
        className={cn(
          "inline-flex items-center gap-[7px] text-[11px] text-[var(--text-muted)]",
          variant === "pill" && "rounded-full bg-[var(--surface-01)] px-[10px] py-[3px]",
          className
        )}
      >
        <span style={{ background: "var(--text-muted)" }} className="h-[7px] w-[7px] flex-none rounded-full" />
        {children}
      </span>
    )
  }

  const { dot, text, fill } = TONE_VARS[tone]

  return (
    <span
      style={variant === "pill" ? { background: fill } : undefined}
      className={cn(
        "inline-flex items-center gap-[7px] text-[11px]",
        variant === "pill" && "rounded-full px-[10px] py-[3px]",
        className
      )}
    >
      <span style={{ background: dot }} className="h-[7px] w-[7px] flex-none rounded-full" />
      <span style={{ color: text }}>{children}</span>
    </span>
  )
}
