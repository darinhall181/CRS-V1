import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from "react"
import { cn } from "@/lib/utils"
import { FOCUS_RING } from "./shared"

export type ChipVariant = "default" | "selected" | "disabled"

export interface ChipProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ChipVariant
  icon?: ReactNode
}

// Elevation Kit — Chip/default (surface/01 + elevation/small) ·
// Chip/selected (interactive blue, no shadow) · Chip/disabled (opacity .5).
// Usage rule #3: pills stay reserved for true pills — chips, toggles, search, map pins.
export const Chip = forwardRef<HTMLButtonElement, ChipProps>(function Chip(
  { variant = "default", icon, className, children, disabled, ...props },
  ref
) {
  const isDisabled = disabled || variant === "disabled"

  return (
    <button
      ref={ref}
      disabled={isDisabled}
      className={cn(
        "inline-flex h-8 items-center gap-[7px] rounded-full border-none px-[14px] font-sans text-xs transition-colors",
        variant === "selected" && "bg-[var(--interactive-default)] text-white",
        variant === "default" &&
          "bg-[var(--surface-01)] text-[var(--text-secondary)] shadow-[var(--elevation-small)] hover:bg-[var(--surface-02)]",
        variant === "disabled" &&
          "cursor-default bg-[var(--surface-01)] text-[var(--text-subtle)] opacity-50",
        variant !== "disabled" && !isDisabled && "cursor-pointer",
        FOCUS_RING,
        className
      )}
      {...props}
    >
      {icon}
      {children}
    </button>
  )
})
