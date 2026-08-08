import type { ReactNode } from "react"
import { cn } from "@/lib/utils"

export interface PhotoWellProps {
  /** Real image element, e.g. next/image — rendered as-is, contained. */
  children?: ReactNode
  placeholder?: string
  radius?: number
  fit?: "contain" | "cover"
  className?: string
}

// Not a port of the prototype's <image-slot> custom element (prototype runtime
// only, per the handoff README) — a plain placeholder well for real photography
// to be dropped into later. Product photography should use object-fit: contain.
export function PhotoWell({ children, placeholder = "Photo", radius = 8, fit = "contain", className }: PhotoWellProps) {
  return (
    <div
      style={{ borderRadius: radius }}
      className={cn(
        "flex h-full w-full items-center justify-center overflow-hidden bg-[var(--surface-01)] text-[10px] text-[var(--text-subtle)]",
        className
      )}
    >
      {children ? (
        <div className={cn("h-full w-full", fit === "contain" ? "[&>*]:object-contain" : "[&>*]:object-cover")}>
          {children}
        </div>
      ) : (
        placeholder
      )}
    </div>
  )
}
