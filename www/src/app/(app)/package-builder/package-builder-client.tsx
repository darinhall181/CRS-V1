"use client"

import { useMemo, useState } from "react"
import Image from "next/image"
import {
  Plus,
  Camera,
  Aperture,
  Wrench,
  Focus,
  Video,
  MessageSquare,
  Search,
  ChevronDown,
  ChevronRight,
  X,
  ArrowUpRight,
} from "lucide-react"
import { Sheet, SheetContent, SheetTitle, SheetDescription } from "@/components/ui/sheet"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Checkbox } from "@/components/ui/checkbox"
import { Button } from "@/components/ui/button"
import {
  GEAR_CATEGORY_LABELS,
  STATUS_STYLES,
  type ContextTab,
  type GearCategory,
  type GearItem,
  type PackageLineItem,
} from "./types"
import { addPackageItemAction, removePackageItemAction } from "./actions"

const VENDOR_NAME = "DaVinci Rentals"

const CATEGORY_ORDER: GearCategory[] = ["camera", "lenses", "support", "focus", "video"]
const CATEGORY_ICONS: Record<GearCategory, typeof Camera> = {
  camera: Camera,
  lenses: Aperture,
  support: Wrench,
  focus: Focus,
  video: Video,
}

function fmt(n: number): string {
  return n.toLocaleString("en-US")
}
function fmtMoney(n: number): string {
  return `$${fmt(Math.round(n))}`
}

export function PackageBuilderClient({
  catalog,
  initialLineItems,
  productionName,
  packageName,
  packageId,
  shootDays,
  approvedBudget,
}: {
  catalog: GearItem[]
  initialLineItems: PackageLineItem[]
  productionName: string
  packageName: string
  packageId: string | null
  shootDays: number
  approvedBudget: number
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
  const [collapsed, setCollapsed] = useState<Set<GearCategory>>(new Set())
  const [bulkSelected, setBulkSelected] = useState<Set<string>>(new Set())

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
        return sum + (gear ? gear.rate.dayRate * l.qty * l.days : 0)
      }, 0)
      return { category, lines, total }
    })
  }, [lineItems, gearById])

  const grandTotal = groups.reduce((sum, g) => sum + g.total, 0)
  const totalItemCount = lineItems.reduce((sum, l) => sum + l.qty, 0)
  const dailyRate = lineItems.reduce((sum, l) => {
    const gear = gearById.get(l.gearId)
    return sum + (gear ? gear.rate.dayRate * l.qty : 0)
  }, 0)
  const remaining = approvedBudget - grandTotal
  const budgetPct = Math.min(100, Math.round((grandTotal / approvedBudget) * 100))

  const selectedLine = lineItems.find((l) => l.id === selectedLineId) ?? null
  const selectedGear = selectedLine ? gearById.get(selectedLine.gearId) ?? null : null

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

  function toggleCollapsed(category: GearCategory) {
    setCollapsed((prev) => {
      const next = new Set(prev)
      if (next.has(category)) next.delete(category)
      else next.add(category)
      return next
    })
  }

  function toggleBulk(lineId: string) {
    setBulkSelected((prev) => {
      const next = new Set(prev)
      if (next.has(lineId)) next.delete(lineId)
      else next.add(lineId)
      return next
    })
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

  const drawerResults = catalog.filter((g) => {
    if (drawerCategory !== "all" && g.category !== drawerCategory) return false
    if (drawerSearch && !g.name.toLowerCase().includes(drawerSearch.toLowerCase())) return false
    return true
  })

  return (
    <div className="flex flex-col h-[calc(100vh-56px)] bg-[var(--bg-base)] text-[var(--text-primary)]">
      {/* ── Top bar ─────────────────────────────────────────────────────── */}
      <div className="h-[52px] flex-none flex items-center gap-3 px-4 border-b border-[var(--border-subtle)]">
        <div className="w-5 h-5 rounded bg-[var(--interactive-default)]" />
        <span className="text-[13px] font-semibold">{productionName} — {packageName}</span>
        <span className="font-mono text-[11px] text-[var(--text-muted)]">
          v1 · {shootDays} shoot days · {VENDOR_NAME}
        </span>
        <div className="w-px h-[18px] bg-[var(--border-default)]" />
        <span className="font-mono text-[11px] text-[var(--text-subtle)]">saved just now</span>
        <div className="flex-1" />
        <div className="flex items-center gap-2 rounded-md border border-[var(--border-subtle)] px-2.5 py-1">
          <span className="font-mono text-[11px] text-[var(--text-secondary)]">
            {fmtMoney(grandTotal)} / {fmtMoney(approvedBudget)}
          </span>
          <div className="w-16 h-1.5 rounded-full bg-[var(--bg-overlay)] overflow-hidden">
            <div
              className="h-full rounded-full"
              style={{
                width: `${budgetPct}%`,
                background: budgetPct >= 100 ? "var(--semantic-warning)" : "var(--interactive-default)",
              }}
            />
          </div>
        </div>
        <Button variant="ghost" size="sm" className="h-7 text-[11px] text-[var(--text-secondary)]">
          Export CSV
        </Button>
        <Button variant="ghost" size="sm" className="h-7 text-[11px] text-[var(--text-secondary)] gap-1">
          Versions <ChevronDown className="w-3 h-3" />
        </Button>
        <Button
          size="sm"
          className="h-7 text-[12px] gap-1"
          style={{ background: "var(--accent-sunset)", color: "var(--accent-sunset-ink)" }}
        >
          Send quote <ArrowUpRight className="w-3.5 h-3.5" />
        </Button>
      </div>

      <div className="flex-1 flex min-h-0 relative">
        {/* ── Icon rail ─────────────────────────────────────────────────── */}
        <div className="w-[58px] flex-none border-r border-[var(--border-subtle)] flex flex-col items-center gap-2 py-3">
          <button
            onClick={() => openDrawer("all")}
            className="w-[38px] h-[38px] rounded-lg flex items-center justify-center transition-colors"
            style={{ background: "var(--interactive-default)" }}
            aria-label="Add gear"
          >
            <Plus className="w-4 h-4 text-[var(--text-primary)]" />
          </button>
          <span className="text-[8px] font-medium uppercase tracking-wide text-[var(--text-subtle)]">add</span>
          <div className="w-6 h-px my-1 bg-[var(--border-subtle)]" />
          {CATEGORY_ORDER.map((cat) => {
            const Icon = CATEGORY_ICONS[cat]
            return (
              <button
                key={cat}
                onClick={() => openDrawer(cat)}
                title={GEAR_CATEGORY_LABELS[cat]}
                className="w-[38px] h-[30px] rounded-md border border-dashed border-[var(--border-default)] flex items-center justify-center text-[var(--text-muted)] hover:text-[var(--text-secondary)] hover:border-[var(--border-default)] transition-colors"
              >
                <Icon className="w-4 h-4" />
              </button>
            )
          })}
          <div className="flex-1" />
          <button
            onClick={() => setRightTab("notes")}
            className="w-[38px] h-[30px] rounded-md flex items-center justify-center text-[var(--text-muted)] hover:bg-[var(--bg-overlay)] transition-colors"
            aria-label="Notes"
          >
            <MessageSquare className="w-4 h-4" />
          </button>
        </div>

        {/* ── Center: grid ──────────────────────────────────────────────── */}
        <div className="flex-1 min-w-0 flex flex-col">
          <div className="flex items-center gap-2 px-3 py-1.5 border-b border-[var(--border-subtle)] flex-none">
            <div className="flex items-center gap-2 rounded-md border border-[var(--border-default)] bg-[var(--bg-overlay)] px-2.5 py-1 min-w-[180px]">
              <Search className="w-3.5 h-3.5 text-[var(--text-subtle)]" />
              <span className="font-mono text-[11px] text-[var(--text-subtle)]">
                Filter {lineItems.length} items…
              </span>
            </div>
            <Button variant="ghost" size="sm" className="h-6 text-[11px] text-[var(--text-secondary)] gap-1">
              Group: category <ChevronDown className="w-3 h-3" />
            </Button>
            <Button variant="ghost" size="sm" className="h-6 text-[11px] text-[var(--text-secondary)] gap-1">
              Columns <ChevronDown className="w-3 h-3" />
            </Button>
            <Button variant="ghost" size="sm" className="h-6 text-[11px] text-[var(--text-secondary)] gap-1">
              Sort <ChevronDown className="w-3 h-3" />
            </Button>
            <div className="flex-1" />
            <span className="font-mono text-[11px] text-[var(--text-subtle)]">⌘K add</span>
            <span className="font-mono text-[11px] text-[var(--text-subtle)]">⌥↑↓ move</span>
            <span className="font-mono text-[11px] text-[var(--text-subtle)]">⌫ remove</span>
          </div>

          {bulkSelected.size > 0 && (
            <div
              className="flex items-center gap-2 px-3 py-1.5 flex-none"
              style={{ background: "rgba(61,85,168,0.10)", borderBottom: "1px solid var(--border-subtle)" }}
            >
              <span className="text-[12px] font-semibold">{bulkSelected.size} selected</span>
              <Button variant="secondary" size="sm" className="h-6 text-[11px]">Move to…</Button>
              <Button variant="secondary" size="sm" className="h-6 text-[11px]">Set qty</Button>
              <Button variant="secondary" size="sm" className="h-6 text-[11px]">Mark optional</Button>
              <Button variant="secondary" size="sm" className="h-6 text-[11px]" onClick={removeBulkSelected}>
                Remove
              </Button>
              <div className="flex-1" />
              <button
                onClick={() => setBulkSelected(new Set())}
                className="font-mono text-[11px] text-[var(--text-muted)] hover:text-[var(--text-secondary)] flex items-center gap-1"
              >
                clear <X className="w-3 h-3" />
              </button>
            </div>
          )}

          <div className="flex-1 overflow-auto min-h-0">
            <div className="flex sticky top-0 bg-[var(--bg-base)] border-b border-[var(--border-default)] px-3 z-10">
              <span className="w-6" />
              <ColHeader className="flex-1">Item</ColHeader>
              <ColHeader className="w-[126px]">SKU</ColHeader>
              <ColHeader className="w-[92px]">Availability</ColHeader>
              <ColHeader className="w-10 text-right">Qty</ColHeader>
              <ColHeader className="w-10 text-right">Days</ColHeader>
              <ColHeader className="w-[72px] text-right">Day rate</ColHeader>
              <ColHeader className="w-[84px] text-right">Line total</ColHeader>
              <ColHeader className="w-[42px] text-center">Note</ColHeader>
            </div>

            {groups.map(({ category, lines, total }) => {
              const isCollapsed = collapsed.has(category)
              return (
                <div key={category}>
                  <button
                    onClick={() => toggleCollapsed(category)}
                    className="w-full flex items-center px-3 py-1.5 border-b border-[var(--border-subtle)]"
                    style={{ background: "var(--bg-surface)" }}
                  >
                    <span className="w-6 text-[var(--text-muted)]">
                      {isCollapsed ? <ChevronRight className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
                    </span>
                    <span className="flex-1 text-left text-[12px] font-semibold">
                      {GEAR_CATEGORY_LABELS[category].toUpperCase()}
                    </span>
                    <span className="font-mono text-[11px] text-[var(--text-muted)]">
                      {lines.length ? `${lines.length} items · ${fmtMoney(total)}` : "empty — add"}
                    </span>
                  </button>

                  {!isCollapsed &&
                    lines.map((line) => {
                      const gear = gearById.get(line.gearId)
                      if (!gear) return null
                      const style = STATUS_STYLES[line.status]
                      const lineTotal = gear.rate.dayRate * line.qty * line.days
                      return (
                        <div
                          key={line.id}
                          onClick={() => {
                            setSelectedLineId(line.id)
                            setRightTab("detail")
                          }}
                          className="flex items-center px-3 border-b border-[var(--border-hairline)] cursor-pointer transition-colors"
                          style={{
                            background: selectedLineId === line.id ? "rgba(61,85,168,0.08)" : "transparent",
                          }}
                        >
                          <span className="w-6 py-2" onClick={(e) => { e.stopPropagation(); toggleBulk(line.id) }}>
                            <Checkbox checked={bulkSelected.has(line.id)} />
                          </span>
                          <Cell className="flex-1 text-[13px] text-[var(--text-primary)] font-medium">
                            {gear.name}
                          </Cell>
                          <Cell className="w-[126px] font-mono text-[11px] text-[var(--text-subtle)]">
                            {gear.sku}
                          </Cell>
                          <Cell className="w-[92px] font-mono text-[11px]">
                            {gear.rate.source === "vendor" ? (
                              <span style={{ color: "var(--semantic-success)" }}>
                                In stock ({gear.rate.quantityOnHand ?? "—"})
                              </span>
                            ) : (
                              <span className="text-[var(--text-muted)]">Est. rate</span>
                            )}
                          </Cell>
                          <Cell className="w-10 text-right font-mono text-[12px]">{line.qty}</Cell>
                          <Cell className="w-10 text-right font-mono text-[12px]">{line.days}</Cell>
                          <Cell className="w-[72px] text-right font-mono text-[12px]">
                            {fmtMoney(gear.rate.dayRate)}
                          </Cell>
                          <Cell className="w-[84px] text-right font-mono text-[12px]">
                            {fmtMoney(lineTotal)}
                          </Cell>
                          <Cell className="w-[42px] text-center">
                            <span
                              className="inline-flex items-center gap-1 rounded-full px-1.5 py-0.5 text-[10px] font-mono"
                              style={{ background: style.bg, color: style.text }}
                            >
                              <span className="w-1 h-1 rounded-full" style={{ background: style.dot }} />
                            </span>
                          </Cell>
                        </div>
                      )
                    })}

                  <button
                    onClick={() => openDrawer(category)}
                    className="w-full flex items-center px-3 border-b border-[var(--border-hairline)] text-left"
                  >
                    <span className="w-6 py-2 text-[var(--text-subtle)]">
                      <Plus className="w-3.5 h-3.5" />
                    </span>
                    <span className="flex-1 py-2 font-mono text-[11px] text-[var(--text-subtle)]">
                      Type to add {GEAR_CATEGORY_LABELS[category].toLowerCase()}… (⌘K)
                    </span>
                  </button>
                </div>
              )
            })}
          </div>

          <div className="flex-none border-t border-[var(--border-default)] flex items-center px-3" style={{ background: "var(--bg-surface)" }}>
            <span className="w-6" />
            <span className="flex-1 py-2.5 text-[13px] font-semibold">Total — {totalItemCount} items</span>
            <span className="w-[126px]" />
            <span className="w-[92px]" />
            <span className="w-10 text-right font-mono text-[12px] py-2.5">{shootDays}</span>
            <span className="w-[72px] text-right text-[13px] font-semibold py-2.5">{fmtMoney(dailyRate)}</span>
            <span className="w-[84px] text-right text-[13px] font-semibold py-2.5">{fmtMoney(grandTotal)}</span>
            <span className="w-[42px]" />
          </div>
        </div>

        {/* ── Right panel ───────────────────────────────────────────────── */}
        <div className="w-[296px] flex-none border-l border-[var(--border-subtle)] flex flex-col min-h-0">
          <Tabs value={rightTab} onValueChange={(v) => setRightTab(v as ContextTab)}>
            <TabsList className="w-full h-auto rounded-none bg-transparent border-b border-[var(--border-subtle)] p-0">
              <TabsTrigger
                value="detail"
                className="flex-1 rounded-none text-[12px] py-2.5 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:border-b-2"
                style={{ borderColor: rightTab === "detail" ? "var(--interactive-default)" : "transparent" }}
              >
                Detail
              </TabsTrigger>
              <TabsTrigger
                value="budget"
                className="flex-1 rounded-none text-[12px] py-2.5 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:border-b-2"
                style={{ borderColor: rightTab === "budget" ? "var(--interactive-default)" : "transparent" }}
              >
                Budget
              </TabsTrigger>
              <TabsTrigger
                value="notes"
                className="flex-1 rounded-none text-[12px] py-2.5 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:border-b-2"
                style={{ borderColor: rightTab === "notes" ? "var(--interactive-default)" : "transparent" }}
              >
                Notes
              </TabsTrigger>
            </TabsList>
          </Tabs>

          <div className="flex-1 overflow-auto p-3">
            {rightTab === "detail" && selectedGear && selectedLine && (
              <DetailPanel gear={selectedGear} line={selectedLine} />
            )}
            {rightTab === "detail" && !selectedGear && (
              <p className="text-[12px] text-[var(--text-subtle)]">Select a line item to see detail.</p>
            )}
            {rightTab === "budget" && (
              <BudgetPanel
                groups={groups}
                grandTotal={grandTotal}
                remaining={remaining}
                shootDays={shootDays}
                approvedBudget={approvedBudget}
              />
            )}
            {rightTab === "notes" && <NotesPanel />}
          </div>
        </div>

        {/* ── Catalog drawer ────────────────────────────────────────────── */}
        <Sheet open={drawerOpen} onOpenChange={setDrawerOpen}>
          <SheetContent
            side="left"
            className="w-[430px] sm:max-w-[430px] p-3 border-r border-[var(--border-default)]"
            style={{ background: "var(--bg-base)" }}
          >
            <SheetTitle className="sr-only">Gear catalog</SheetTitle>
            <SheetDescription className="sr-only">
              Search and add gear to the package from the {VENDOR_NAME} catalog.
            </SheetDescription>
            <div className="flex items-center gap-2 mb-3">
              <span className="text-[15px] font-semibold">Catalog</span>
              <span className="font-mono text-[11px] text-[var(--text-muted)]">
                {VENDOR_NAME} · {catalog.length} Canon items
              </span>
            </div>
            <div className="flex items-center gap-2 rounded-lg border border-[var(--border-default)] bg-[var(--bg-overlay)] px-2.5 py-2 mb-3">
              <Search className="w-3.5 h-3.5 text-[var(--text-subtle)]" />
              <input
                autoFocus
                value={drawerSearch}
                onChange={(e) => setDrawerSearch(e.target.value)}
                placeholder="Search gear…"
                className="flex-1 bg-transparent outline-none font-mono text-[12px] text-[var(--text-primary)] placeholder:text-[var(--text-subtle)]"
              />
            </div>
            <div className="flex flex-wrap gap-1.5 mb-3">
              {(["all", ...CATEGORY_ORDER] as const).map((cat) => (
                <button
                  key={cat}
                  onClick={() => setDrawerCategory(cat)}
                  className="rounded-full px-2.5 py-1 text-[11px] font-medium border transition-colors"
                  style={
                    drawerCategory === cat
                      ? { background: "var(--interactive-default)", borderColor: "var(--interactive-default)", color: "var(--text-primary)" }
                      : { borderColor: "var(--border-default)", color: "var(--text-secondary)" }
                  }
                >
                  {cat === "all" ? "All" : GEAR_CATEGORY_LABELS[cat]}
                </button>
              ))}
            </div>
            <div className="grid grid-cols-3 gap-2.5 overflow-auto pr-1" style={{ maxHeight: "calc(100vh - 200px)" }}>
              {drawerResults.map((gear) => (
                <div
                  key={gear.id}
                  className="rounded-lg overflow-hidden border"
                  style={{ borderColor: "var(--border-subtle)", background: "var(--bg-surface)" }}
                >
                  <div className="h-[52px] flex items-center justify-center" style={{ background: "var(--bg-overlay)" }}>
                    {gear.imageUrl ? (
                      <Image src={gear.imageUrl} alt={gear.name} width={52} height={52} className="object-contain h-full" />
                    ) : (
                      <Camera className="w-5 h-5 text-[var(--text-subtle)]" />
                    )}
                  </div>
                  <div className="p-2 flex flex-col gap-1">
                    <p className="text-[11px] leading-tight line-clamp-2 text-[var(--text-primary)]">{gear.name}</p>
                    <div className="flex items-center justify-between">
                      <span className="font-mono text-[10px] text-[var(--text-muted)] flex items-center gap-1">
                        {gear.rate.source === "vendor" && (
                          <span className="w-1 h-1 rounded-full" style={{ background: "var(--semantic-success)" }} />
                        )}
                        {fmtMoney(gear.rate.dayRate)}/day
                      </span>
                      <button
                        onClick={() => addToPackage(gear)}
                        className="rounded-full w-5 h-5 flex items-center justify-center"
                        style={{ background: "var(--interactive-default)" }}
                        aria-label={`Add ${gear.name}`}
                      >
                        <Plus className="w-3 h-3 text-[var(--text-primary)]" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
              {drawerResults.length === 0 && (
                <p className="col-span-3 text-[12px] text-[var(--text-subtle)] py-6 text-center">
                  No matches.
                </p>
              )}
            </div>
            <p className="font-mono text-[10px] text-[var(--text-subtle)] mt-3">
              Adds land in the grid behind; drawer stays open for a run of adds, esc to close.
            </p>
          </SheetContent>
        </Sheet>
      </div>
    </div>
  )
}

// ─── Small building blocks ─────────────────────────────────────────────────────

function ColHeader({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return (
    <span className={`py-1.5 text-[11px] font-medium uppercase tracking-wide text-[var(--text-muted)] border-l border-[var(--border-subtle)] px-2 ${className}`}>
      {children}
    </span>
  )
}

function Cell({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return <span className={`py-2 border-l border-[var(--border-hairline)] px-2 ${className}`}>{children}</span>
}

function DetailPanel({ gear, line }: { gear: GearItem; line: PackageLineItem }) {
  const style = STATUS_STYLES[line.status]
  return (
    <div>
      <div className="w-full h-[100px] rounded-md mb-2.5 flex items-center justify-center" style={{ background: "var(--bg-overlay)" }}>
        {gear.imageUrl ? (
          <Image src={gear.imageUrl} alt={gear.name} width={100} height={100} className="object-contain h-full" />
        ) : (
          <Camera className="w-6 h-6 text-[var(--text-subtle)]" />
        )}
      </div>
      <p className="text-[14px] font-semibold">{gear.name}</p>
      <p className="font-mono text-[11px] text-[var(--text-muted)] mb-2.5">
        {gear.sku} · {GEAR_CATEGORY_LABELS[gear.category]}
      </p>
      <div className="flex items-baseline gap-1.5 pb-2.5 border-b border-[var(--border-subtle)]">
        <span className="text-[20px] font-semibold font-mono">{fmtMoney(gear.rate.dayRate)}</span>
        <span className="font-mono text-[11px] text-[var(--text-muted)]">
          per day · {line.days} days · {fmtMoney(gear.rate.dayRate * line.qty * line.days)}
        </span>
      </div>
      <p className="text-[11px] font-medium uppercase tracking-wide text-[var(--text-muted)] mt-3 mb-2">Rate source</p>
      {gear.rate.source === "vendor" ? (
        <p className="text-[12px] text-[var(--text-secondary)]">
          {gear.rate.vendorName} · {gear.rate.quantityOnHand ?? "—"} in stock
          {gear.rate.weekRate && (
            <span className="text-[var(--text-muted)]"> · {fmtMoney(gear.rate.weekRate)}/week</span>
          )}
        </p>
      ) : (
        <p className="text-[12px] text-[var(--text-muted)]">
          Estimated from MSRP — no vendor quote yet
        </p>
      )}
      <p className="text-[11px] font-medium uppercase tracking-wide text-[var(--text-muted)] mt-3 mb-2">Status</p>
      <span
        className="inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 text-[11px] font-medium"
        style={{ background: style.bg, color: style.text }}
      >
        <span className="w-1.5 h-1.5 rounded-full" style={{ background: style.dot }} />
        {style.label}
      </span>
      <div className="flex gap-1.5 mt-3.5">
        <Button variant="secondary" size="sm" className="h-7 text-[11px]">Duplicate</Button>
        <Button variant="secondary" size="sm" className="h-7 text-[11px]">Find substitute</Button>
      </div>
    </div>
  )
}

function BudgetPanel({
  groups,
  grandTotal,
  remaining,
  shootDays,
  approvedBudget,
}: {
  groups: { category: GearCategory; lines: PackageLineItem[]; total: number }[]
  grandTotal: number
  remaining: number
  shootDays: number
  approvedBudget: number
}) {
  const maxTotal = Math.max(1, ...groups.map((g) => g.total))
  return (
    <div>
      <p className="text-[11px] font-medium uppercase tracking-wide text-[var(--text-muted)] mb-2">Daily by category</p>
      <div className="flex items-end gap-2 h-[78px] mb-3.5">
        {groups.map((g) => (
          <div key={g.category} className="flex-1 flex flex-col items-center gap-1">
            <div
              className="w-full rounded-sm"
              style={{
                height: `${Math.max(4, (g.total / maxTotal) * 56)}px`,
                background: g.total > 0 ? "var(--interactive-default)" : "var(--bg-overlay)",
              }}
            />
            <span className="font-mono text-[10px] text-[var(--text-subtle)]">
              {GEAR_CATEGORY_LABELS[g.category].split(" ")[0].slice(0, 4)}
            </span>
          </div>
        ))}
      </div>
      <div className="rounded-lg border border-[var(--border-subtle)] p-2.5 flex flex-col gap-1.5 mb-3">
        <Row label={`At day rate · ${shootDays}d`} value={fmtMoney(grandTotal)} />
        <Row label="Approved" value={fmtMoney(approvedBudget)} />
        <div className="flex justify-between pt-1.5 border-t border-[var(--border-subtle)]">
          <span className="text-[14px] font-semibold">Remaining</span>
          <span
            className="text-[14px] font-semibold font-mono"
            style={{ color: remaining >= 0 ? "var(--semantic-success)" : "var(--semantic-warning)" }}
          >
            {remaining >= 0 ? fmtMoney(remaining) : `-${fmtMoney(Math.abs(remaining))}`}
          </span>
        </div>
      </div>
      <div className="rounded-lg border border-dashed border-[var(--border-default)] p-2.5 flex flex-col gap-1.5">
        <p className="text-[11px] font-medium uppercase tracking-wide text-[var(--text-muted)]">Approval</p>
        <p className="text-[11px] leading-relaxed text-[var(--text-secondary)]">
          Not yet submitted for approval. Sending the RFQ will notify the producer.
        </p>
        <Button variant="secondary" size="sm" className="h-7 text-[11px] self-start">Request change</Button>
      </div>
    </div>
  )
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between">
      <span className="font-mono text-[11px] text-[var(--text-subtle)]">{label}</span>
      <span className="font-mono text-[11px] text-[var(--text-secondary)]">{value}</span>
    </div>
  )
}

function NotesPanel() {
  return (
    <div>
      <p className="text-[11px] font-medium uppercase tracking-wide text-[var(--text-muted)] mb-2.5">Notes & activity</p>
      <div className="rounded-lg border border-[var(--border-subtle)] p-2.5 mb-2">
        <p className="text-[12px] text-[var(--text-secondary)]">No comments yet on this package.</p>
      </div>
      <div className="rounded-lg border border-dashed border-[var(--border-default)] p-2.5 flex flex-col gap-2">
        <span className="font-mono text-[11px] text-[var(--text-subtle)]">Reply or @mention…</span>
        <div className="flex gap-1.5">
          <Button size="sm" className="h-6 text-[11px]" style={{ background: "var(--interactive-default)" }}>Post</Button>
          <Button variant="secondary" size="sm" className="h-6 text-[11px]">@ mention</Button>
        </div>
      </div>
    </div>
  )
}
