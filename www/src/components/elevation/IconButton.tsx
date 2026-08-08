import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from "react"
import { cn } from "@/lib/utils"
import { FOCUS_RING } from "./shared"

export type IconButtonShape = "circle" | "square"
// "pager" = surface/02 + elevation/1 (back/forward nav, section pagers).
// "control" = surface/03 + elevation/small (add actions, action-strip trailing button).
export type IconButtonTone = "pager" | "control"

const TONE_CLASSES: Record<IconButtonTone, string> = {
  pager: "bg-[var(--surface-02)] shadow-[var(--elevation-1)] hover:bg-[var(--surface-02-hover)]",
  control: "bg-[var(--surface-03)] shadow-[var(--elevation-small)] hover:bg-[var(--surface-03-hover)]",
}

const DEFAULT_SIZE: Record<IconButtonShape, number> = { circle: 40, square: 34 }

export interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  icon: ReactNode
  shape?: IconButtonShape
  tone?: IconButtonTone
  size?: number
  "aria-label": string
}

// Elevation Kit — IconButton/circle (back & pager) · IconButton/square (add-to-package).
// Disabled = surface/disabled + text-subtle + opacity .6, per the handoff's back-at-start example.
export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(function IconButton(
  { icon, shape = "circle", tone, size, disabled, className, ...props },
  ref
) {
  const resolvedTone = tone ?? (shape === "circle" ? "pager" : "control")
  const resolvedSize = size ?? DEFAULT_SIZE[shape]

  return (
    <button
      ref={ref}
      disabled={disabled}
      style={{ width: resolvedSize, height: resolvedSize }}
      className={cn(
        "inline-flex flex-none items-center justify-center border-none text-[var(--text-primary)] transition-colors",
        shape === "circle" ? "rounded-full" : "rounded-[8px]",
        disabled
          ? "cursor-default bg-[var(--surface-disabled)] text-[var(--text-subtle)] opacity-60 shadow-none"
          : cn("cursor-pointer", TONE_CLASSES[resolvedTone]),
        FOCUS_RING,
        className
      )}
      {...props}
    >
      {icon}
    </button>
  )
})
