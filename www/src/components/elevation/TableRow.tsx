import type { CSSProperties, ReactNode } from "react"
import { cn } from "@/lib/utils"

export interface TableRowProps {
  /** CSS grid-template-columns — same string on the header row and every data row. */
  columns: string
  children: ReactNode
  onClick?: () => void
  active?: boolean
  className?: string
}

// Elevation Kit — Table/headerRow: uppercase 11px muted labels, no card
// background (sits inside a Table/shell wrapper).
export function TableHeaderRow({ columns, children, className }: Omit<TableRowProps, "onClick" | "active">) {
  return (
    <div
      style={{ gridTemplateColumns: columns } as CSSProperties}
      className={cn(
        "grid items-center gap-3.5 px-5 py-3 text-[11px] font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]",
        className
      )}
    >
      {children}
    </div>
  )
}

// Elevation Kit — Table/row: 48–56px min height, hairline top divider
// (elevation/divider), row/hover on hover, row/active tint while expanded.
// Pair with Table/shell (surface/02 + elevation/1 + 16px radius) as the
// outer card — this component only renders the row itself so it composes
// with an optional expanded-detail sibling underneath (see History.dc.html).
export function TableRow({ columns, children, onClick, active, className }: TableRowProps) {
  return (
    <div
      onClick={onClick}
      style={{ gridTemplateColumns: columns } as CSSProperties}
      className={cn(
        "grid min-h-12 items-center gap-3.5 px-5 shadow-[inset_0_1px_0_var(--elevation-divider)] transition-colors",
        onClick && "cursor-pointer hover:bg-[var(--row-hover)]",
        active && "bg-[var(--row-active)]",
        className
      )}
    >
      {children}
    </div>
  )
}

export function TableShell({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div
      className={cn(
        "min-w-0 overflow-x-auto overflow-y-hidden rounded-[16px] bg-[var(--surface-02)] shadow-[var(--elevation-1)]",
        className
      )}
    >
      {children}
    </div>
  )
}
