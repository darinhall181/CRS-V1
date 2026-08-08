import { forwardRef, type ButtonHTMLAttributes } from "react"
import { cn } from "@/lib/utils"
import { FOCUS_RING } from "./shared"

export type ButtonVariant = "primary" | "accent" | "raised" | "ghost"

const VARIANT_CLASSES: Record<ButtonVariant, string> = {
  primary: "bg-[var(--interactive-default)] text-white hover:bg-[var(--interactive-hover)]",
  accent: "bg-[var(--accent-sunset)] text-[var(--accent-sunset-ink)] hover:opacity-90",
  raised:
    "bg-[var(--surface-03)] text-[var(--text-primary)] shadow-[var(--elevation-small)] hover:bg-[var(--surface-03-hover)]",
  ghost: "bg-transparent text-[var(--text-secondary)] hover:bg-[var(--ghost-hover)]",
}

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant
}

// Elevation Kit — Button/primary · Button/accent (one sunset CTA per screen,
// usage rule #4) · Button/raised (replaces the old outlined secondary) · Button/ghost.
export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant = "primary", className, disabled, ...props },
  ref
) {
  return (
    <button
      ref={ref}
      disabled={disabled}
      className={cn(
        "inline-flex h-[38px] items-center justify-center rounded-[8px] border-none px-5 font-sans text-[13px] font-medium transition-colors disabled:cursor-default disabled:opacity-40",
        VARIANT_CLASSES[variant],
        FOCUS_RING,
        className
      )}
      {...props}
    />
  )
})
