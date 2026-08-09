import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { useState } from "react"
import { TableShell, TableHeaderRow, TableRow } from "./TableRow"
import { StatusBadge } from "./StatusBadge"

const meta: Meta<typeof TableRow> = {
  title: "Elevation Kit/TableRow",
  parameters: { layout: "padded" },
}
export default meta
type Story = StoryObj<typeof TableRow>

const CRM_COLS = "minmax(0,1.6fr) minmax(0,1.2fr) minmax(0,1.4fr) minmax(0,1fr) 110px"

// CRM — account table, no expansion.
export const CRMAccountTable: Story = {
  render: () => (
    <TableShell>
      <TableHeaderRow columns={CRM_COLS}>
        <span>Account</span>
        <span>Preferred contact</span>
        <span>Linked productions</span>
        <span>Last contact</span>
        <span className="text-right">Open value</span>
      </TableHeaderRow>
      {[
        { name: "Keslow West", contact: "Dana Kwon", productions: "Ridgeline, Marrow", last: "Aug 6", value: "$48,200" },
        { name: "Otto Nemenz", contact: "Ines Fuentes", productions: "Halcyon spot", last: "Aug 5", value: "$31,900" },
      ].map((r) => (
        <TableRow key={r.name} columns={CRM_COLS}>
          <span className="truncate text-[13px] font-medium">{r.name}</span>
          <span className="truncate text-[12.5px]">{r.contact}</span>
          <span className="truncate text-[12.5px] text-[var(--text-secondary)]">{r.productions}</span>
          <span className="font-mono text-xs text-[var(--text-secondary)]">{r.last}</span>
          <span className="text-right font-mono text-xs">{r.value}</span>
        </TableRow>
      ))}
    </TableShell>
  ),
}

const HISTORY_COLS = "96px 108px 116px minmax(0,1.25fr) minmax(0,1.2fr) 118px 116px 26px"

// History — ledger table with click-to-expand row (active tint on the row/active token).
export const HistoryLedgerExpand: Story = {
  render: function Render() {
    const [open, setOpen] = useState(false)
    return (
      <TableShell>
        <TableHeaderRow columns={HISTORY_COLS}>
          <span>Date</span>
          <span>Reference</span>
          <span>Type</span>
          <span>Rental house</span>
          <span>Production</span>
          <span className="text-right">Amount</span>
          <span>Status</span>
          <span />
        </TableHeaderRow>
        <div>
          <TableRow columns={HISTORY_COLS} onClick={() => setOpen((v) => !v)} active={open}>
            <span className="font-mono text-xs text-[var(--text-secondary)]">Aug 6</span>
            <span className="font-mono text-xs text-[var(--text-secondary)]">QTE-4412</span>
            <span className="text-[12.5px]">Quote</span>
            <span className="truncate text-[12.5px]">Keslow West</span>
            <span className="truncate text-[12.5px] text-[var(--text-secondary)]">Ridgeline — A-cam</span>
            <span className="text-right font-mono text-[12.5px]">$48,200</span>
            <StatusBadge tone="info">Sent</StatusBadge>
            <span className="text-[var(--text-subtle)]">{open ? "▲" : "▼"}</span>
          </TableRow>
          {open && (
            <div className="grid grid-cols-4 gap-3.5 px-5 pb-5 pt-1 text-[12.5px] text-[var(--text-secondary)]">
              <div>Sent by Elena Vasquez</div>
              <div>Contact Dana Kwon</div>
              <div>Aug 14 – Sep 1 (18 d)</div>
              <div>Expires Aug 13</div>
            </div>
          )}
        </div>
      </TableShell>
    )
  },
}
