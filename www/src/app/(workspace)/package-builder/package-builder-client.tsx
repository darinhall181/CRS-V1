"use client"

import { useMemo, useState } from "react"
import Image from "next/image"
import { Plus, Search, X, ChevronDown, FileSpreadsheet } from "lucide-react"
import { Sheet, SheetContent, SheetTitle, SheetDescription } from "@/components/ui/sheet"
import { Checkbox } from "@/components/ui/checkbox"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { StatusBadge, SegmentedToggle, IconButton, Chip, GearCard, type StatusTone } from "@/components/elevation"
import {
  GEAR_CATEGORY_LABELS,
  type ContextTab,
  type GearCategory,
  type GearItem,
  type PackageLineItem,
} from "./types"
import { addPackageItemAction, removePackageItemAction, updatePackageItemQtyAction } from "./actions"
import { PackageBuilderSidebar } from "./package-builder-sidebar"
import { PackageBuilderTopBar } from "./package-builder-topbar"

const VENDOR_NAME = "DaVinci Rentals"
const CATEGORY_ORDER: GearCategory[] = ["camera", "lenses", "support", "focus", "video"]
const CATEGORY_ABBR: Record<GearCategory, string> = {
  camera: "Cam",
  lenses: "Lens",
  support: "Supp",
  focus: "Foc",
  video: "Vid",
}
// Outer wrapper's left edge is the row's own `gap-[26px]` (shared with the
// sidebar↔center gap, for a consistent rhythm) — only its own right-side
// 26px outer margin is this wrapper's padding. SegmentedToggle needs a real
// pixel width, so this subtracts that plus the card's own px-3 (12px)
// tab-row padding. Getting this wrong makes the toggle wider than its
// flex-col parent, which silently overflows the "Notes" panel underneath.
// 266 makes the card's left edge land flush with "Export CSV"'s left edge —
// its right edge already matches "Send quote"'s right edge exactly (both are
// anchored to the row's own right inset), so only the left edge needed to move.
const RIGHT_PANEL_WIDTH = 266
const RIGHT_PANEL_CARD_WIDTH = RIGHT_PANEL_WIDTH - 26 // 240
const RIGHT_PANEL_TOGGLE_WIDTH = RIGHT_PANEL_CARD_WIDTH - 12 * 2 // 288 — tab row's px-3
const TAB_LABELS = ["Detail", "Budget", "Notes"] as const

function fmt(n: number): string {
  return n.toLocaleString("en-US")
}
function fmtMoney(n: number): string {
  return `$${fmt(Math.round(n))}`
}

// Derived, not fabricated — rolls up the real per-line statuses into one
// package-level badge (no `packages.status` column exists yet to read this
// from directly).
// Three stages, matching the package's real lifecycle: nothing sent yet
// (Draft) → a quote is out (Sent) → something on it has been accepted/
// confirmed, so it's actively being fulfilled (In Progress).
function derivePackageStatus(lineItems: PackageLineItem[]): { tone: StatusTone; label: string } {
  if (lineItems.length === 0 || lineItems.every((l) => l.status === "draft")) {
    return { tone: "neutral", label: "Draft" }
  }
  if (lineItems.some((l) => l.status === "approved" || l.status === "confirmed")) {
    return { tone: "success", label: "In Progress" }
  }
  return { tone: "info", label: "Sent" }
}

export function PackageBuilderClient({
  catalog,
  initialLineItems,
  productionName,
  packageName,
  packageId,
  shootDays,
  approvedBudget,
  userName,
  companyName,
}: {
  catalog: GearItem[]
  initialLineItems: PackageLineItem[]
  productionName: string
  packageName: string
  packageId: string | null
  shootDays: number
  approvedBudget: number
  userName: string
  companyName: string | null
}) {
  const gearById = useMemo(() => new Map(catalog.map((g) => [g.id, g])), [catalog])

  const [lineItems, setLineItems] = useState<PackageLineItem[]>(initialLineItems)
  const [selectedLineId, setSelectedLineId] = useState<string | null>(
    initialLineItems[0]?.id ?? null
  )
  const [rightTab, setRightTab] = useState<ContextTab>("detail")
  const [drawerOpen, setDrawerOpen] = useState(false)
  const [drawerCategory, setDrawerCategory] = useState<GearCategory | "all">("all")
  const [drawerSearch, setDrawerSearch] = useState("")
  const [bulkSelected, setBulkSelected] = useState<Set<string>>(new Set())
  // Client-only for now — no `optional` column on package_items yet, so this
  // doesn't survive a reload. Real enough to be visible/toggleable, not
  // fabricated data (nothing claims it's saved).
  const [optionalIds, setOptionalIds] = useState<Set<string>>(new Set())
  const [mainQuery, setMainQuery] = useState("")
  const [groupBy, setGroupBy] = useState<"category" | "brand">("category")
  // Lifted page-wide (not scoped to the Budget tab) — matches the "Package
  // Builder - Elevation" handoff, where the day/week toggle re-prices the
  // whole table, not just the budget summary.
  const [rateMode, setRateMode] = useState<"day" | "week">("day")

  // ─── Derived: rate-mode-aware pricing ──────────────────────────────────────

  function rateOf(gear: GearItem): number {
    if (rateMode === "day") return gear.rate.dayRate
    // Real weekRate wins when a vendor quoted one; otherwise a plain 7x-day
    // estimate (flagged the same way single-day estimates already are).
    return gear.rate.weekRate ?? gear.rate.dayRate * 7
  }
  const rateUnit = rateMode === "day" ? "/day" : "/wk"
  const periods = rateMode === "day" ? shootDays : Math.ceil(shootDays / 7)

  // ─── Derived: grouped line items with per-group + grand totals ────────────

  const groups = useMemo(() => {
    const byCategory = new Map<GearCategory, PackageLineItem[]>()
    for (const cat of CATEGORY_ORDER) byCategory.set(cat, [])
    for (const line of lineItems) {
      const gear = gearById.get(line.gearId)
      if (!gear) continue
      byCategory.get(gear.category)?.push(line)
    }
    return CATEGORY_ORDER.map((category) => {
      const lines = byCategory.get(category) ?? []
      const total = lines.reduce((sum, l) => {
        const gear = gearById.get(l.gearId)
        return sum + (gear ? rateOf(gear) * l.qty * periods : 0)
      }, 0)
      return { category, lines, total }
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lineItems, gearById, rateMode])

  // Display-only grouping for the main table — category mode mirrors `groups`
  // above exactly; brand mode groups by real GearItem.brandName instead.
  // Totals/budget/footer always stay category-based (`groups`), independent
  // of how the table is currently displayed.
  const displayGroups = useMemo(() => {
    if (groupBy === "category") {
      return groups.map((g) => ({
        key: g.category as string,
        label: GEAR_CATEGORY_LABELS[g.category],
        category: g.category as GearCategory | null,
        lines: g.lines,
        total: g.total,
      }))
    }
    const byBrand = new Map<string, PackageLineItem[]>()
    for (const line of lineItems) {
      const gear = gearById.get(line.gearId)
      if (!gear) continue
      const key = gear.brandName
      if (!byBrand.has(key)) byBrand.set(key, [])
      byBrand.get(key)!.push(line)
    }
    return Array.from(byBrand.entries())
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([brandName, lines]) => ({
        key: brandName,
        label: brandName,
        category: null as GearCategory | null,
        lines,
        total: lines.reduce((sum, l) => {
          const gear = gearById.get(l.gearId)
          return sum + (gear ? rateOf(gear) * l.qty * periods : 0)
        }, 0),
      }))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [groupBy, groups, lineItems, gearById, rateMode])

  const grandTotal = groups.reduce((sum, g) => sum + g.total, 0)
  const totalItemCount = lineItems.reduce((sum, l) => sum + l.qty, 0)
  const periodRate = lineItems.reduce((sum, l) => {
    const gear = gearById.get(l.gearId)
    return sum + (gear ? rateOf(gear) * l.qty : 0)
  }, 0)
  const remaining = approvedBudget - grandTotal
  const budgetPct = Math.min(100, Math.round((grandTotal / approvedBudget) * 100))
  const packageStatus = derivePackageStatus(lineItems)

  const selectedLine = lineItems.find((l) => l.id === selectedLineId) ?? null
  const selectedGear = selectedLine ? gearById.get(selectedLine.gearId) ?? null : null

  const query = mainQuery.trim().toLowerCase()
  function matchesQuery(gear: GearItem | undefined): boolean {
    return !query || !gear ? !query : gear.name.toLowerCase().includes(query)
  }

  // ─── Actions ────────────────────────────────────────────────────────────────

  function openDrawer(category: GearCategory | "all") {
    setDrawerCategory(category)
    setDrawerSearch("")
    setDrawerOpen(true)
  }

  async function addToPackage(gear: GearItem) {
    const tempId = `temp-${gear.id}-${Date.now()}`
    const newLine: PackageLineItem = {
      id: tempId,
      gearId: gear.id,
      qty: 1,
      days: shootDays,
      status: "draft",
      notesCount: 0,
    }
    // Optimistic add — swap in the real DB id once the write confirms, or
    // roll back if it fails.
    setLineItems((prev) => [...prev, newLine])
    setSelectedLineId(tempId)
    setRightTab("detail")

    if (!packageId) return // no real package to persist to (shouldn't happen in the demo)

    try {
      const { id: realId } = await addPackageItemAction(packageId, gear.id)
      setLineItems((prev) => prev.map((l) => (l.id === tempId ? { ...l, id: realId } : l)))
      setSelectedLineId((prev) => (prev === tempId ? realId : prev))
    } catch (err) {
      console.error("Failed to add package item:", err)
      setLineItems((prev) => prev.filter((l) => l.id !== tempId))
      setSelectedLineId((prev) => (prev === tempId ? null : prev))
    }
  }

  function toggleBulk(lineId: string) {
    setBulkSelected((prev) => {
      const next = new Set(prev)
      if (next.has(lineId)) next.delete(lineId)
      else next.add(lineId)
      return next
    })
  }

  function markOptionalSelected() {
    setOptionalIds((prev) => {
      const next = new Set(prev)
      for (const id of bulkSelected) next.add(id)
      return next
    })
    setBulkSelected(new Set())
  }

  async function removeBulkSelected() {
    const idsToRemove = Array.from(bulkSelected)
    setLineItems((prev) => prev.filter((l) => !bulkSelected.has(l.id)))
    setBulkSelected(new Set())

    const realIds = idsToRemove.filter((id) => !id.startsWith("temp-"))
    try {
      await Promise.all(realIds.map((id) => removePackageItemAction(id)))
    } catch (err) {
      console.error("Failed to remove package item(s):", err)
      // Not rolling back the optimistic removal here — a failed delete on an
      // already-hidden row is a rarer, lower-stakes edge case than a failed
      // add; surfacing a console error is enough for the current demo scope.
    }
  }

  async function removeLine(lineId: string) {
    setLineItems((prev) => prev.filter((l) => l.id !== lineId))
    setBulkSelected((prev) => {
      const next = new Set(prev)
      next.delete(lineId)
      return next
    })
    if (!lineId.startsWith("temp-")) {
      try {
        await removePackageItemAction(lineId)
      } catch (err) {
        console.error("Failed to remove package item:", err)
      }
    }
  }

  function updateLineQty(lineId: string, qty: number) {
    setLineItems((prev) => prev.map((l) => (l.id === lineId ? { ...l, qty } : l)))
  }

  async function commitLineQty(lineId: string, qty: number) {
    if (lineId.startsWith("temp-")) return // not persisted yet — the add flow will carry the current qty
    try {
      await updatePackageItemQtyAction(lineId, qty)
    } catch (err) {
      console.error("Failed to update quantity:", err)
    }
  }

  const drawerResults = catalog.filter((g) => {
    if (drawerCategory !== "all" && g.category !== drawerCategory) return false
    if (drawerSearch && !g.name.toLowerCase().includes(drawerSearch.toLowerCase())) return false
    return true
  })

  return (
    <div className="flex h-screen flex-col bg-[var(--bg-base)] text-[var(--text-primary)]">
      {/* Top bar spans the full screen width — sits above the sidebar rather
          than beside it, so the sidebar starts below it instead of hitting
          the top of the viewport. */}
      <PackageBuilderTopBar userName={userName} />

      <div className="flex flex-1 min-h-0">
        <PackageBuilderSidebar companyName={companyName} onAddGear={() => openDrawer("all")} />
        <div className="flex flex-1 flex-col min-w-0">
          {/* ── Page header ─────────────────────────────────────────────────── */}
        <div className="flex flex-none items-center gap-3 px-[26px] pt-8">
          <span className="text-3xl font-semibold tracking-[-0.02em]">
            {productionName} — {packageName}
          </span>
          <StatusBadge tone={packageStatus.tone}>{packageStatus.label}</StatusBadge>
          <span className="text-[11px] text-[var(--text-subtle)]">Saved just now</span>
        </div>

        {/* ── Action row ──────────────────────────────────────────────────── */}
        <div className="flex flex-none items-center gap-2.5 px-[26px] pt-3">
          <div className="flex h-[38px] flex-none items-center gap-2.5 rounded-[14px] bg-[var(--bg-overlay)] px-4 shadow-[var(--elevation-2)]">
            <Search size={14} strokeWidth={2} className="text-[var(--text-muted)]" />
            <input
              value={mainQuery}
              onChange={(e) => setMainQuery(e.target.value)}
              placeholder="Filter"
              className="w-[90px] bg-transparent text-xs text-[var(--text-primary)] outline-none placeholder:text-[var(--text-subtle)]"
            />
            <span className="h-4 w-px bg-[var(--elevation-divider)]" />
            <DropdownMenu>
              <DropdownMenuTrigger className="flex items-center gap-1 whitespace-nowrap text-xs text-[var(--text-primary)] outline-none">
                Grouped by {groupBy}
                <ChevronDown size={11} strokeWidth={2.4} className="text-[var(--text-muted)]" />
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start">
                <DropdownMenuItem onClick={() => setGroupBy("category")}>Category</DropdownMenuItem>
                <DropdownMenuItem onClick={() => setGroupBy("brand")}>Brand</DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>

          <div className="flex-1" />

          <button
            type="button"
            className="flex h-[38px] flex-none items-center gap-[7px] rounded-[14px] bg-[var(--surface-03)] px-4 text-xs font-medium text-[var(--text-primary)] transition-colors hover:bg-[var(--surface-03-hover)]"
          >
            <FileSpreadsheet size={14} strokeWidth={2} />
            Export CSV
          </button>

          <button
            type="button"
            className="flex h-[38px] flex-none items-center gap-[7px] rounded-[14px] px-4 text-xs font-medium shadow-[var(--elevation-2)] transition-opacity hover:opacity-90"
            style={{ background: "var(--accent-sunset)", color: "var(--accent-sunset-ink)" }}
          >
            Send quote ↗
          </button>
        </div>

        <div className="flex flex-1 min-h-0 gap-[26px]">
          {/* ── Center: grouped item cards ──────────────────────────────── */}
          <div className="flex flex-1 min-w-0 flex-col gap-3 pl-[26px] pb-[26px] pt-4">
            {bulkSelected.size > 0 && (
              <div className="flex h-11 flex-none items-center gap-2.5 rounded-xl bg-[var(--surface-01)] px-3.5 shadow-[var(--elevation-2)]">
                <span className="text-xs font-medium">{bulkSelected.size} selected</span>
                <div className="flex items-center gap-2">
                  <BulkChip onClick={markOptionalSelected}>Mark optional</BulkChip>
                  <BulkChip tone="danger" onClick={removeBulkSelected}>Remove</BulkChip>
                </div>
                <div className="flex-1" />
                <button
                  onClick={() => setBulkSelected(new Set())}
                  className="flex items-center gap-1 text-[11px] text-[var(--text-muted)] transition-colors hover:text-[var(--text-primary)]"
                >
                  Clear selection <X size={11} />
                </button>
              </div>
            )}

            <div className="flex flex-none items-center px-3.5">
              <span className="w-[30px]" />
              <span className="flex-1 px-2" />
              <span className="w-[130px] px-2 text-center text-[11px] font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]">Availability</span>
              <span className="w-14 px-2 text-center text-[11px] font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]">Qty</span>
              <span className="w-14 px-2 text-center text-[11px] font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]">Days</span>
              <span className="w-[90px] px-2 text-center text-[11px] font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]">Rate</span>
              <span className="w-[100px] px-2 text-right text-[11px] font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]">Total</span>
              <span className="ml-2.5 w-[26px]" />
            </div>

            <div className="flex-1 overflow-auto flex flex-col gap-3 pr-1">
              {displayGroups.map(({ key, label, category, lines, total }) => {
                const displayLines = lines.filter((l) => matchesQuery(gearById.get(l.gearId)))
                const displayTotal = query
                  ? displayLines.reduce((sum, l) => {
                      const gear = gearById.get(l.gearId)
                      return sum + (gear ? rateOf(gear) * l.qty * periods : 0)
                    }, 0)
                  : total
                return (
                  <div
                    key={key}
                    className="flex-none overflow-hidden rounded-[14px] bg-[var(--surface-02)] shadow-[var(--elevation-1)]"
                  >
                    <div className="flex h-[42px] items-center gap-2.5 px-3.5">
                      <span className="text-[11px] font-semibold uppercase tracking-[0.06em] text-[var(--text-secondary)]">
                        {label}
                      </span>
                      {displayLines.length > 0 && (
                        <span className="font-mono text-xs text-[var(--text-muted)]">
                          {displayLines.length} items · {fmtMoney(displayTotal)}
                        </span>
                      )}
                      <div className="flex-1" />
                      <IconButton
                        shape="square"
                        size={26}
                        icon={<Plus size={12} strokeWidth={2.4} />}
                        aria-label={`Add to ${label}`}
                        onClick={() => openDrawer(category ?? "all")}
                      />
                    </div>

                    {displayLines.map((line) => {
                      const gear = gearById.get(line.gearId)
                      if (!gear) return null
                      const isSelected = selectedLineId === line.id
                      const isBulked = bulkSelected.has(line.id)
                      const lineTotal = rateOf(gear) * line.qty * periods
                      return (
                        <div
                          key={line.id}
                          onClick={() => {
                            setSelectedLineId((prev) => (prev === line.id ? null : line.id))
                            setRightTab("detail")
                          }}
                          className="flex min-h-11 cursor-pointer items-center px-3.5 shadow-[inset_0_1px_0_var(--elevation-divider)] transition-colors hover:bg-[var(--row-hover)]"
                          style={{ background: isSelected ? "var(--row-active)" : isBulked ? "rgba(61,85,168,0.08)" : "transparent" }}
                        >
                          <span className="flex w-[30px] items-center" onClick={(e) => { e.stopPropagation(); toggleBulk(line.id) }}>
                            <Checkbox checked={isBulked} />
                          </span>
                          <span className="flex flex-1 items-center gap-2 px-2 text-[13px]">
                            {gear.name}
                            {optionalIds.has(line.id) && (
                              <span className="rounded-full bg-[var(--neutral-fill)] px-[7px] py-px text-[10px] font-medium text-[var(--text-muted)]">
                                Optional
                              </span>
                            )}
                          </span>
                          <span
                            className="w-[130px] px-2 text-center text-xs"
                            style={{ color: gear.rate.source === "vendor" ? "var(--success-text)" : "var(--text-muted)" }}
                          >
                            {gear.rate.source === "vendor" ? `In stock (${gear.rate.quantityOnHand ?? "—"})` : "Not confirmed"}
                          </span>
                          <input
                            type="number"
                            min={1}
                            value={line.qty}
                            onClick={(e) => e.stopPropagation()}
                            onChange={(e) => updateLineQty(line.id, Math.max(1, Number(e.target.value) || 1))}
                            onBlur={(e) => commitLineQty(line.id, Math.max(1, Number(e.target.value) || 1))}
                            className="w-14 flex-none rounded-md bg-transparent px-2 text-center font-mono text-[13px] text-[var(--text-secondary)] outline-none transition-colors hover:bg-[var(--ghost-hover)] focus-visible:bg-[var(--surface-01)] focus-visible:text-[var(--text-primary)] [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                          />
                          <span className="w-14 px-2 text-center font-mono text-[13px] text-[var(--text-secondary)]">{line.days}</span>
                          <span className="w-[90px] px-2 text-center font-mono text-[13px]">{fmtMoney(rateOf(gear))}{rateUnit}</span>
                          <span className="w-[100px] px-2 text-right font-mono text-[13px]">{fmtMoney(lineTotal)}</span>
                          <IconButton
                            shape="square"
                            size={26}
                            icon={<X size={11} strokeWidth={2.4} />}
                            aria-label={`Remove ${gear.name}`}
                            className="ml-2.5 flex-none"
                            onClick={(e) => { e.stopPropagation(); removeLine(line.id) }}
                          />
                        </div>
                      )
                    })}

                    {lines.length === 0 && (
                      <button
                        onClick={() => openDrawer(category ?? "all")}
                        className="flex min-h-11 w-full items-center gap-2 px-3.5 text-left shadow-[inset_0_1px_0_var(--elevation-divider)] transition-colors hover:bg-[var(--row-hover)]"
                      >
                        <Plus size={13} strokeWidth={2.2} className="text-[var(--text-subtle)]" />
                        <span className="text-xs text-[var(--text-subtle)]">Nothing in this group yet — add gear</span>
                      </button>
                    )}
                    {lines.length > 0 && displayLines.length === 0 && (
                      <div className="flex min-h-11 items-center px-3.5 shadow-[inset_0_1px_0_var(--elevation-divider)]">
                        <span className="text-xs text-[var(--text-subtle)]">No items match &ldquo;{mainQuery}&rdquo;</span>
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          </div>

          {/* ── Right panel ─────────────────────────────────────────────── */}
          <div className="flex-none pt-3 pb-[26px] pr-[26px]" style={{ width: RIGHT_PANEL_WIDTH }}>
            <div className="flex h-full min-w-0 flex-col overflow-hidden rounded-2xl bg-[var(--surface-02)] shadow-[var(--elevation-1)]">
              <div className="flex-none px-3 pt-3">
                <SegmentedToggle
                  options={TAB_LABELS}
                  value={TAB_LABELS.indexOf(
                    rightTab === "detail" ? "Detail" : rightTab === "budget" ? "Budget" : "Notes"
                  )}
                  onChange={(i) => setRightTab((["detail", "budget", "notes"] as const)[i])}
                  width={RIGHT_PANEL_TOGGLE_WIDTH}
                  height={34}
                  aria-label="Panel"
                />
              </div>

              <div className="flex-1 overflow-auto p-3.5">
                {rightTab === "detail" && selectedGear && selectedLine && (
                  <DetailPanel gear={selectedGear} rateOf={rateOf} rateUnit={rateUnit} />
                )}
                {rightTab === "detail" && !selectedGear && (
                  <div>
                    <div className="mb-3.5 flex h-[172px] items-center justify-center rounded-[10px] bg-[var(--surface-01)]">
                      <span className="text-[11px] uppercase tracking-[0.04em] text-[var(--text-subtle)]">
                        Click on item to see image
                      </span>
                    </div>
                    <p className="text-xs text-[var(--text-subtle)]">
                      Click to get information on a specific gear item.
                    </p>
                  </div>
                )}
                {rightTab === "budget" && (
                  <BudgetPanel
                    groups={groups}
                    grandTotal={grandTotal}
                    remaining={remaining}
                    budgetPct={budgetPct}
                    periods={periods}
                    approvedBudget={approvedBudget}
                    rateMode={rateMode}
                  />
                )}
                {rightTab === "notes" && <NotesPanel />}
              </div>

              {/* Re-prices the whole table (not just this panel), but only
                  shown while on Budget — elsewhere it's just visual noise. */}
              {rightTab === "budget" && (
                <div className="flex flex-none items-center gap-2 px-3.5 pb-3.5 pt-1">
                  <span className="text-[11px] text-[var(--text-muted)]">Rate</span>
                  <SegmentedToggle
                    options={["Day", "Week"]}
                    value={rateMode === "day" ? 0 : 1}
                    onChange={(i) => setRateMode(i === 0 ? "day" : "week")}
                    width={104}
                    height={26}
                    aria-label="Rate period"
                  />
                </div>
              )}
            </div>
          </div>
        </div>

        {/* ── Footer ──────────────────────────────────────────────────────── */}
        <div className="flex-none px-[26px] pb-3.5">
          <div className="flex h-14 items-center rounded-[14px] bg-[var(--surface-02)] px-[18px] shadow-[var(--elevation-1)]">
            <span className="text-[13px] font-semibold">Total — {totalItemCount} items</span>
            <div className="flex-1" />
            <span className="px-2.5 font-mono text-xs text-[var(--text-muted)]">
              {shootDays} shoot days · {VENDOR_NAME}
            </span>
            <span className="w-24 px-2 text-right font-mono text-[13px] font-semibold">
              {fmtMoney(periodRate)}{rateUnit}
            </span>
            <span className="w-[120px] px-2 text-right font-mono text-[17px] font-semibold">{fmtMoney(grandTotal)}</span>
          </div>
        </div>

        {/* ── Catalog drawer ──────────────────────────────────────────────── */}
        <Sheet open={drawerOpen} onOpenChange={setDrawerOpen}>
          <SheetContent
            side="left"
            className="w-[460px] gap-0 border-none p-4 sm:max-w-[460px]"
            style={{ background: "var(--surface-00)" }}
          >
            <SheetTitle className="sr-only">Gear catalog</SheetTitle>
            <SheetDescription className="sr-only">
              Search and add gear to the package from the {VENDOR_NAME} catalog.
            </SheetDescription>

            <div className="flex h-full flex-col gap-3.5">
              <div className="flex flex-none items-baseline gap-2">
                <span className="text-[15px] font-semibold">Catalog</span>
                <span className="font-mono text-xs text-[var(--text-muted)]">
                  {VENDOR_NAME} · {catalog.length} Canon items
                </span>
              </div>

              <div className="flex h-[38px] flex-none items-center gap-2.5 rounded-[14px] bg-[var(--surface-01)] px-4">
                <Search size={14} strokeWidth={2} className="text-[var(--text-muted)]" />
                <input
                  autoFocus
                  value={drawerSearch}
                  onChange={(e) => setDrawerSearch(e.target.value)}
                  placeholder="Search gear…"
                  className="flex-1 bg-transparent text-xs text-[var(--text-primary)] outline-none placeholder:text-[var(--text-subtle)]"
                />
              </div>

              <div className="flex flex-none flex-wrap gap-1.5">
                {(["all", ...CATEGORY_ORDER] as const).map((cat) => (
                  <Chip
                    key={cat}
                    variant={drawerCategory === cat ? "selected" : "default"}
                    onClick={() => setDrawerCategory(cat)}
                  >
                    {cat === "all" ? "All" : GEAR_CATEGORY_LABELS[cat]}
                  </Chip>
                ))}
              </div>

              <div className="grid flex-1 auto-rows-min grid-cols-2 gap-3 overflow-auto pr-1 pb-1">
                {drawerResults.map((gear) => (
                  <GearCard
                    key={gear.id}
                    photo={
                      gear.imageUrl ? (
                        <Image src={gear.imageUrl} alt={gear.name} fill className="object-contain" />
                      ) : undefined
                    }
                    name={gear.name}
                    spec={GEAR_CATEGORY_LABELS[gear.category]}
                    rate={fmtMoney(gear.rate.dayRate)}
                    onAdd={() => addToPackage(gear)}
                  />
                ))}
                {drawerResults.length === 0 && (
                  <p className="col-span-2 py-6 text-center text-xs text-[var(--text-subtle)]">No matches.</p>
                )}
              </div>

              <p className="flex-none text-[11px] text-[var(--text-subtle)]">
                Adds land in the grid behind — the drawer stays open for a run of adds, esc to close.
              </p>
            </div>
          </SheetContent>
        </Sheet>
        </div>
      </div>
    </div>
  )
}

// ─── Small building blocks ─────────────────────────────────────────────────────

function BulkChip({
  children,
  tone = "default",
  onClick,
}: {
  children: React.ReactNode
  tone?: "default" | "danger"
  onClick?: () => void
}) {
  return (
    <button
      onClick={onClick}
      className="flex h-7 items-center rounded-lg bg-[var(--surface-03)] px-2.5 text-xs transition-colors hover:bg-[var(--surface-03-hover)]"
      style={{ color: tone === "danger" ? "var(--danger-text)" : "var(--text-primary)" }}
    >
      {children}
    </button>
  )
}

function FactRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex justify-between gap-2.5">
      <span className="text-xs text-[var(--text-muted)]">{label}</span>
      <span className="font-mono text-xs text-[var(--text-secondary)]">{value}</span>
    </div>
  )
}

function DetailPanel({
  gear,
  rateOf,
  rateUnit,
}: {
  gear: GearItem
  rateOf: (gear: GearItem) => number
  rateUnit: string
}) {
  const rate = rateOf(gear)
  return (
    <div>
      <div className="relative mb-3.5 h-[172px] rounded-[10px] bg-[var(--surface-01)]">
        {gear.imageUrl ? (
          <Image src={gear.imageUrl} alt={gear.name} fill className="object-contain p-1" />
        ) : (
          <div className="flex h-full items-center justify-center">
            <span className="text-[11px] uppercase tracking-[0.04em] text-[var(--text-subtle)]">Product photo</span>
          </div>
        )}
      </div>
      <p className="mb-3.5 text-[15px] font-semibold">{gear.name}</p>
      <div className="mb-3.5 flex items-baseline gap-2">
        <span className="font-mono text-2xl font-light">{fmtMoney(rate)}</span>
        <span className="text-xs text-[var(--text-muted)]">{rateUnit === "/day" ? "per day" : "per week"}</span>
      </div>

      <div className="rounded-[10px] bg-[var(--surface-01)] p-3">
        {gear.rate.source === "vendor" ? (
          <span className="text-xs text-[var(--text-secondary)]">
            {gear.rate.vendorName} · {gear.rate.quantityOnHand ?? "—"} in stock
            {gear.rate.weekRate && ` · ${fmtMoney(gear.rate.weekRate)}/wk`}
          </span>
        ) : (
          <span className="text-xs text-[var(--text-muted)]">Estimated from MSRP — no vendor quote yet</span>
        )}
      </div>
    </div>
  )
}

function BudgetPanel({
  groups,
  grandTotal,
  remaining,
  budgetPct,
  periods,
  approvedBudget,
  rateMode,
}: {
  groups: { category: GearCategory; lines: PackageLineItem[]; total: number }[]
  grandTotal: number
  remaining: number
  budgetPct: number
  periods: number
  approvedBudget: number
  rateMode: "day" | "week"
}) {
  const maxTotal = Math.max(1, ...groups.map((g) => g.total))
  const periodLabel = `Est. price for ${periods} ${rateMode === "day" ? "days" : "weeks"}`
  return (
    <div>
      <p className="mb-3 text-[11px] font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]">Daily by category</p>
      <div className="mb-[18px] flex h-[104px] items-end gap-2.5">
        {groups.map((g) => (
          <div key={g.category} className="flex flex-1 flex-col items-center gap-1.5">
            <div
              className="w-full rounded"
              style={{
                height: `${Math.max(3, Math.round((g.total / maxTotal) * 84))}px`,
                background: g.total > 0 ? "var(--interactive-default)" : "var(--bg-overlay)",
              }}
            />
            <span className="text-[11px] text-[var(--text-subtle)]">{CATEGORY_ABBR[g.category]}</span>
          </div>
        ))}
      </div>

      {remaining < 0 && (
        <div
          className="mb-3 flex h-[34px] items-center rounded-[10px] px-3.5"
          style={{ background: "var(--status-overbudget-bg)" }}
        >
          <span className="font-mono text-xs" style={{ color: "var(--status-overbudget-text)" }}>
            Exceeds approved budget by {fmtMoney(Math.abs(remaining))}
          </span>
        </div>
      )}

      <div className="mb-3 flex flex-col gap-2.5 rounded-xl bg-[var(--surface-01)] p-3.5">
        <FactRow label={periodLabel} value={fmtMoney(grandTotal)} />
        <FactRow label="Approved" value={fmtMoney(approvedBudget)} />
        <div className="h-[5px] overflow-hidden rounded-full bg-[var(--surface-00)] shadow-[var(--elevation-inset)]">
          <div
            className="h-full rounded-full"
            style={{ width: `${budgetPct}%`, background: "var(--interactive-default)" }}
          />
        </div>
        <div className="flex items-baseline justify-between pt-1">
          <span className="text-[13px] font-semibold">Remaining</span>
          <span
            className="font-mono text-[17px] font-semibold"
            style={{ color: remaining >= 0 ? "var(--success-text)" : "var(--warning-text)" }}
          >
            {remaining >= 0 ? fmtMoney(remaining) : `-${fmtMoney(Math.abs(remaining))}`}
          </span>
        </div>
      </div>

      <div className="flex flex-col gap-2.5 rounded-xl bg-[var(--surface-01)] p-3.5">
        <p className="text-[11px] font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]">Approval</p>
        <span className="text-xs leading-relaxed text-[var(--text-secondary)]">
          Not yet submitted for approval. Sending the RFQ will notify the producer.
        </span>
        <button className="flex h-[30px] w-fit items-center rounded-lg bg-[var(--surface-03)] px-3 text-xs transition-colors hover:bg-[var(--surface-03-hover)]">
          Request change
        </button>
      </div>
    </div>
  )
}

function NotesPanel() {
  return (
    <div>
      <p className="mb-3 text-[11px] font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]">Notes &amp; activity</p>
      <div className="mb-2.5 rounded-xl bg-[var(--surface-01)] p-3">
        <p className="text-xs text-[var(--text-secondary)]">No comments yet on this package.</p>
      </div>
      <div className="flex flex-col gap-2.5 rounded-xl bg-[var(--surface-01)] p-3">
        <span className="text-xs text-[var(--text-subtle)]">Reply or @mention…</span>
        <div className="flex gap-2">
          <button className="flex h-7 items-center rounded-lg px-3 text-xs text-white transition-colors hover:bg-[var(--interactive-hover)]" style={{ background: "var(--interactive-default)" }}>
            Post
          </button>
          <button className="flex h-7 items-center rounded-lg px-3 text-xs text-[var(--text-secondary)] transition-colors hover:bg-[var(--ghost-hover)] hover:text-[var(--text-primary)]">
            @ mention
          </button>
        </div>
      </div>
    </div>
  )
}
