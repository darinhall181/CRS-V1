'use client'

import { useState, useMemo, useCallback } from 'react'
import { CATALOG, INITIAL_PACKAGE, APPROVED_BUDGET_DAILY, SHOOT_DAYS, APPROVED_BUDGET_TOTAL, CATEGORY_LABELS } from './data'
import { STATUS_STYLES } from './types'
import type { GearItem, GearCategory, PackageItems, ExperienceLevel, ContextTab } from './types'

// ─── Helpers ──────────────────────────────────────────────────────────────────

function getItem(id: string): GearItem | undefined {
  return CATALOG.find(g => g.id === id)
}

function fmt(n: number): string {
  return n.toLocaleString('en-US')
}

// ─── Sub-components ───────────────────────────────────────────────────────────

function StatusBadge({ status }: { status: GearItem['status'] }) {
  const s = STATUS_STYLES[status]
  return (
    <span
      className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-medium border"
      style={{
        background: s.bg,
        color: s.text,
        borderColor: s.dot + '33',
      }}
    >
      <span className="w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ background: s.dot }} />
      {s.label}
    </span>
  )
}

function GearCard({
  item,
  isSelected,
  isInPackage,
  onSelect,
  onToggle,
}: {
  item: GearItem
  isSelected: boolean
  isInPackage: boolean
  onSelect: () => void
  onToggle: (e: React.MouseEvent) => void
}) {
  return (
    <div
      onClick={onSelect}
      className="rounded-lg overflow-hidden cursor-pointer transition-colors"
      style={{
        background: isSelected ? '#1E2540' : '#242428',
        border: `0.5px solid ${isSelected ? '#3D55A8' : 'rgba(255,255,255,0.07)'}`,
      }}
    >
      {/* Product image */}
      <div className="h-16 flex items-center justify-center overflow-hidden" style={{ background: '#2E2E34' }}>
        {item.imageUrl ? (
          <img
            src={item.imageUrl}
            alt={item.name}
            className="h-full w-full object-cover"
            style={{ objectPosition: 'center' }}
          />
        ) : (
          <div className="text-[10px] font-mono" style={{ color: '#555560' }}>{item.category.toUpperCase()}</div>
        )}
      </div>
      <div className="p-2">
        <div className="text-[11px] font-medium leading-tight mb-0.5" style={{ color: '#EAEAEA' }}>{item.name}</div>
        <div className="text-[10px] mb-2" style={{ color: '#666672' }}>{item.specSummary}</div>
        <div className="flex items-center justify-between">
          <span className="text-[11px] font-mono" style={{ color: '#9090A0' }}>${fmt(item.dayRate)}/day</span>
          <button
            onClick={onToggle}
            className="w-5 h-5 rounded flex items-center justify-center transition-colors"
            style={{
              background: isInPackage ? 'rgba(74,186,130,0.2)' : 'rgba(61,85,168,0.25)',
              border: `0.5px solid ${isInPackage ? 'rgba(74,186,130,0.4)' : 'rgba(61,85,168,0.4)'}`,
            }}
          >
            {isInPackage ? (
              <svg width="10" height="10" viewBox="0 0 16 16" fill="none" stroke="#4ABA82" strokeWidth="2.5" strokeLinecap="round">
                <path d="M3 8l3.5 3.5L13 5" />
              </svg>
            ) : (
              <svg width="10" height="10" viewBox="0 0 16 16" fill="none" stroke="#7AAEE8" strokeWidth="2.5" strokeLinecap="round">
                <path d="M8 3v10M3 8h10" />
              </svg>
            )}
          </button>
        </div>
      </div>
    </div>
  )
}

function PackageRow({
  item,
  isActive,
  onSelect,
  onRemove,
}: {
  item: GearItem
  isActive: boolean
  onSelect: () => void
  onRemove: (e: React.MouseEvent) => void
}) {
  return (
    <div
      onClick={onSelect}
      className="group flex items-center gap-2.5 px-3.5 py-2.5 cursor-pointer transition-colors border-b last:border-b-0"
      style={{
        background: isActive ? 'rgba(61,85,168,0.08)' : 'transparent',
        borderColor: 'rgba(255,255,255,0.04)',
      }}
    >
      {/* Thumbnail */}
      <div
        className="w-8 h-6 rounded flex items-center justify-center flex-shrink-0 text-[8px] font-mono"
        style={{ background: '#2E2E34', color: '#555560' }}
      >
        {item.category.slice(0, 3).toUpperCase()}
      </div>
      <div className="flex-1 min-w-0">
        <div className="text-xs font-medium truncate" style={{ color: '#EAEAEA' }}>{item.name}</div>
        <div className="text-[10px] font-mono truncate" style={{ color: '#555560' }}>{item.sku}</div>
      </div>
      <span className="text-[11px] font-mono w-6 text-center" style={{ color: '#666672' }}>×1</span>
      <span className="text-[11px] font-mono w-12 text-right" style={{ color: '#9090A0' }}>${fmt(item.dayRate)}</span>
      <button
        onClick={onRemove}
        className="w-4 h-4 rounded flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
        style={{ background: 'transparent' }}
      >
        <svg width="10" height="10" viewBox="0 0 16 16" fill="none" stroke="#666672" strokeWidth="2.2" strokeLinecap="round">
          <path d="M4 4l8 8M12 4l-8 8" />
        </svg>
      </button>
    </div>
  )
}

function PackageSection({
  title,
  category,
  itemIds,
  activeItemId,
  onSelectItem,
  onRemoveItem,
  onBrowseCategory,
}: {
  title: string
  category: GearCategory
  itemIds: string[]
  activeItemId: string
  onSelectItem: (id: string) => void
  onRemoveItem: (id: string, cat: GearCategory) => void
  onBrowseCategory: (cat: GearCategory) => void
}) {
  const [collapsed, setCollapsed] = useState(false)

  const total = itemIds.reduce((sum, id) => {
    const g = getItem(id)
    return sum + (g?.dayRate ?? 0)
  }, 0)

  return (
    <div className="rounded-xl overflow-hidden" style={{ background: '#242428', border: '0.5px solid rgba(255,255,255,0.07)' }}>
      <div
        className="flex items-center gap-2 px-3.5 py-2.5 cursor-pointer"
        style={{ borderBottom: collapsed ? 'none' : '0.5px solid rgba(255,255,255,0.06)' }}
        onClick={() => setCollapsed(c => !c)}
      >
        <svg
          width="12" height="12" viewBox="0 0 16 16" fill="none"
          stroke="#666672" strokeWidth="2" strokeLinecap="round"
          style={{ transform: collapsed ? 'rotate(0deg)' : 'rotate(90deg)', transition: 'transform 0.15s' }}
        >
          <path d="M6 4l4 4-4 4" />
        </svg>
        <span className="text-xs font-medium flex-1" style={{ color: '#EAEAEA' }}>{title}</span>
        <span className="text-[10px]" style={{ color: '#555560' }}>
          {itemIds.length > 0 ? `${itemIds.length} ${itemIds.length === 1 ? 'item' : 'items'}` : 'empty'}
        </span>
        {total > 0 && (
          <span className="text-[11px] font-mono" style={{ color: '#9090A0' }}>${fmt(total)}/day</span>
        )}
      </div>

      {!collapsed && (
        <>
          {itemIds.map(id => {
            const item = getItem(id)
            if (!item) return null
            return (
              <PackageRow
                key={id}
                item={item}
                isActive={activeItemId === id}
                onSelect={() => onSelectItem(id)}
                onRemove={(e) => { e.stopPropagation(); onRemoveItem(id, category) }}
              />
            )
          })}
          {itemIds.length === 0 && (
            <div
              className="flex items-center gap-2.5 px-3.5 py-5 cursor-pointer group"
              onClick={() => onBrowseCategory(category)}
            >
              <div
                className="w-7 h-7 rounded-md flex items-center justify-center flex-shrink-0"
                style={{ border: '0.5px dashed rgba(255,255,255,0.12)' }}
              >
                <svg width="12" height="12" viewBox="0 0 16 16" fill="none" stroke="#444450" strokeWidth="1.8" strokeLinecap="round">
                  <path d="M8 3v10M3 8h10" />
                </svg>
              </div>
              <span className="text-xs" style={{ color: '#444450' }}>
                <span style={{ color: '#555560', fontWeight: 500 }}>Add {title.toLowerCase()}</span> — browse catalog
              </span>
            </div>
          )}
        </>
      )}
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function PackageBuilderPage() {
  const [packageItems, setPackageItems] = useState<PackageItems>({ ...INITIAL_PACKAGE })
  const [activeItemId, setActiveItemId] = useState<string>('alexa35')
  const [activeCategory, setActiveCategory] = useState<string>('all')
  const [searchQuery, setSearchQuery] = useState('')
  const [experienceLevel, setExperienceLevel] = useState<ExperienceLevel>('standard')
  const [contextTab, setContextTab] = useState<ContextTab>('detail')

  // ── Derived state ──────────────────────────────────────────────────────────

  const activeItem = useMemo(() => getItem(activeItemId), [activeItemId])

  const filteredCatalog = useMemo(() => {
    return CATALOG.filter(g => {
      const matchCat = activeCategory === 'all' || g.category === activeCategory
      const q = searchQuery.toLowerCase()
      const matchSearch = !q || g.name.toLowerCase().includes(q) || g.specSummary.toLowerCase().includes(q)
      return matchCat && matchSearch
    })
  }, [activeCategory, searchQuery])

  const allPackageIds = useMemo(() => Object.values(packageItems).flat(), [packageItems])

  const totalDayRate = useMemo(
    () => allPackageIds.reduce((sum, id) => sum + (getItem(id)?.dayRate ?? 0), 0),
    [allPackageIds]
  )

  const budgetPct = Math.min(100, Math.round((totalDayRate / APPROVED_BUDGET_DAILY) * 100))
  const totalEstimate = totalDayRate * SHOOT_DAYS
  const remaining = APPROVED_BUDGET_TOTAL - totalEstimate

  const isInPackage = useCallback(
    (id: string) => allPackageIds.includes(id),
    [allPackageIds]
  )

  // ── Handlers ───────────────────────────────────────────────────────────────

  const toggleItem = useCallback((id: string) => {
    const item = getItem(id)
    if (!item) return
    setPackageItems(prev => {
      const arr = [...(prev[item.category] ?? [])]
      const idx = arr.indexOf(id)
      if (idx >= 0) arr.splice(idx, 1)
      else arr.push(id)
      return { ...prev, [item.category]: arr }
    })
  }, [])

  const removeItem = useCallback((id: string, cat: GearCategory) => {
    setPackageItems(prev => {
      const arr = prev[cat].filter(i => i !== id)
      return { ...prev, [cat]: arr }
    })
  }, [])

  const selectItem = useCallback((id: string) => {
    setActiveItemId(id)
  }, [])

  const browseCategory = useCallback((cat: GearCategory) => {
    setActiveCategory(cat)
  }, [])

  // ── Render ─────────────────────────────────────────────────────────────────

  return (
    <div className="flex flex-col h-screen" style={{ background: '#18181A', color: '#EAEAEA' }}>

      {/* ── Top bar ── */}
      <header
        className="flex items-center gap-3 px-4 h-[52px] flex-shrink-0"
        style={{ borderBottom: '0.5px solid rgba(255,255,255,0.07)' }}
      >
        <div>
          <p className="text-[13px] font-medium" style={{ color: '#EAEAEA' }}>Meridian — Feature Package</p>
          <p className="text-[10px]" style={{ color: '#555560' }}>A-Cam · 18 shoot days · Keslow Camera</p>
        </div>

        <div className="w-px h-4 mx-1" style={{ background: 'rgba(255,255,255,0.1)' }} />

        {/* View toggle (decorative in mockup) */}
        <div className="flex rounded-md overflow-hidden" style={{ background: '#242428', border: '0.5px solid rgba(255,255,255,0.07)' }}>
          {(['grid', 'list', 'split'] as const).map((v, i) => (
            <button key={v} className="px-2 py-1.5" style={{ background: i === 0 ? '#2E2E34' : 'transparent' }}>
              {v === 'grid' && <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke={i === 0 ? '#EAEAEA' : '#666672'} strokeWidth="1.6" strokeLinecap="round"><rect x="2" y="2" width="5" height="5" rx="1"/><rect x="9" y="2" width="5" height="5" rx="1"/><rect x="2" y="9" width="5" height="5" rx="1"/><rect x="9" y="9" width="5" height="5" rx="1"/></svg>}
              {v === 'list' && <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="#666672" strokeWidth="1.6" strokeLinecap="round"><path d="M4 4h9M4 8h9M4 12h9M2 4h.01M2 8h.01M2 12h.01"/></svg>}
              {v === 'split' && <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="#666672" strokeWidth="1.6" strokeLinecap="round"><rect x="2" y="2" width="5" height="12" rx="1"/><rect x="9" y="2" width="5" height="12" rx="1"/></svg>}
            </button>
          ))}
        </div>

        {/* Experience level */}
        <select
          value={experienceLevel}
          onChange={e => setExperienceLevel(e.target.value as ExperienceLevel)}
          className="rounded-md px-2.5 py-1 text-[11px] font-medium cursor-pointer"
          style={{
            background: '#242428',
            border: '0.5px solid rgba(255,255,255,0.08)',
            color: '#9090A0',
          }}
        >
          <option value="guided">Guided</option>
          <option value="standard">Standard</option>
          <option value="pro">Pro</option>
        </select>

        <div className="flex-1" />

        {/* Budget tracker */}
        <div
          className="flex items-center gap-2 rounded-md px-3 py-1.5"
          style={{ background: '#3A2020', border: '0.5px solid rgba(224,107,107,0.25)' }}
        >
          <span className="text-[11px] font-medium" style={{ color: '#E06B6B' }}>Over budget</span>
          <div className="h-1 rounded-full overflow-hidden" style={{ background: '#2E2E34', width: 72 }}>
            <div className="h-full w-full rounded-full" style={{ background: '#E06B6B' }} />
          </div>
          <span className="text-xs font-mono font-medium" style={{ color: '#E06B6B' }}>$20,000</span>
        </div>

        <div className="w-px h-4" style={{ background: 'rgba(255,255,255,0.1)' }} />

        <button
          className="rounded-lg px-3.5 py-1.5 text-xs font-medium transition-colors"
          style={{ background: '#FFCF7B', color: '#2A1F00' }}
        >
          Send quote ↗
        </button>
      </header>

      {/* ── Body ── */}
      <div className="flex flex-1 overflow-hidden">

        {/* ── Left: Catalog ── */}
        <aside
          className="flex flex-col overflow-hidden flex-shrink-0"
          style={{ width: 240, borderRight: '0.5px solid rgba(255,255,255,0.07)' }}
        >
          {/* Search */}
          <div className="p-2.5" style={{ borderBottom: '0.5px solid rgba(255,255,255,0.06)' }}>
            <div className="relative">
              <svg
                width="13" height="13" viewBox="0 0 16 16" fill="none"
                stroke="#555560" strokeWidth="1.8" strokeLinecap="round"
                className="absolute left-2.5 top-1/2 -translate-y-1/2 pointer-events-none"
              >
                <circle cx="7" cy="7" r="4.5" /><path d="M10.5 10.5l2.5 2.5" />
              </svg>
              <input
                type="text"
                placeholder="Search gear…"
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                className="w-full rounded-lg pl-8 pr-3 py-1.5 text-xs outline-none"
                style={{
                  background: '#242428',
                  border: '0.5px solid rgba(255,255,255,0.08)',
                  color: '#EAEAEA',
                }}
              />
            </div>
          </div>

          {/* Category chips */}
          <div className="flex flex-wrap gap-1 p-2" style={{ borderBottom: '0.5px solid rgba(255,255,255,0.06)' }}>
            {Object.entries(CATEGORY_LABELS).map(([cat, label]) => (
              <button
                key={cat}
                onClick={() => setActiveCategory(cat)}
                className="text-[10px] font-medium px-2 py-1 rounded-full transition-colors"
                style={{
                  background: activeCategory === cat ? 'rgba(61,85,168,0.2)' : 'transparent',
                  border: `0.5px solid ${activeCategory === cat ? 'rgba(61,85,168,0.4)' : 'rgba(255,255,255,0.08)'}`,
                  color: activeCategory === cat ? '#7AAEE8' : '#666672',
                }}
              >
                {label}
              </button>
            ))}
          </div>

          {/* Gear cards */}
          <div className="flex-1 overflow-y-auto p-2 flex flex-col gap-1.5">
            {filteredCatalog.map(item => (
              <GearCard
                key={item.id}
                item={item}
                isSelected={activeItemId === item.id}
                isInPackage={isInPackage(item.id)}
                onSelect={() => selectItem(item.id)}
                onToggle={(e) => { e.stopPropagation(); toggleItem(item.id) }}
              />
            ))}
            {filteredCatalog.length === 0 && (
              <p className="text-xs text-center py-8" style={{ color: '#444450' }}>No gear matches your search.</p>
            )}
          </div>
        </aside>

        {/* ── Main: Package canvas ── */}
        <main className="flex-1 overflow-y-auto p-4 flex flex-col gap-3">
          {(['camera', 'lenses', 'support', 'focus', 'video'] as GearCategory[]).map(cat => (
            <PackageSection
              key={cat}
              title={CATEGORY_LABELS[cat]}
              category={cat}
              itemIds={packageItems[cat]}
              activeItemId={activeItemId}
              onSelectItem={selectItem}
              onRemoveItem={removeItem}
              onBrowseCategory={browseCategory}
            />
          ))}
        </main>

        {/* ── Right: Context panel ── */}
        <aside
          className="flex flex-col overflow-hidden flex-shrink-0"
          style={{ width: 220, borderLeft: '0.5px solid rgba(255,255,255,0.07)', background: '#1C1C1F' }}
        >
          {/* Tabs */}
          <div className="flex" style={{ borderBottom: '0.5px solid rgba(255,255,255,0.07)' }}>
            {(['detail', 'budget'] as ContextTab[]).map(tab => (
              <button
                key={tab}
                onClick={() => setContextTab(tab)}
                className="flex-1 py-2.5 text-[11px] font-medium capitalize transition-colors"
                style={{
                  color: contextTab === tab ? '#EAEAEA' : '#555560',
                  borderBottom: contextTab === tab ? '1.5px solid #3D55A8' : '1.5px solid transparent',
                }}
              >
                {tab}
              </button>
            ))}
          </div>

          <div className="flex-1 overflow-y-auto p-3">

            {/* ── Detail tab ── */}
            {contextTab === 'detail' && activeItem && (
              <>
                {/* Product image */}
                <div
                  className="w-full h-24 rounded-lg mb-2.5 overflow-hidden flex items-center justify-center"
                  style={{ background: '#2E2E34' }}
                >
                  {activeItem.imageUrl ? (
                    <img
                      src={activeItem.imageUrl}
                      alt={activeItem.name}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <span className="text-[11px] font-mono" style={{ color: '#555560' }}>
                      {activeItem.category.toUpperCase()}
                    </span>
                  )}
                </div>

                <p className="text-[13px] font-medium leading-snug mb-0.5" style={{ color: '#EAEAEA' }}>{activeItem.name}</p>
                <p className="text-[10px] font-mono mb-2.5" style={{ color: '#555560' }}>{activeItem.sku}</p>

                <div className="flex items-baseline justify-between mb-3 pb-2.5" style={{ borderBottom: '0.5px solid rgba(255,255,255,0.06)' }}>
                  <div>
                    <span className="text-[18px] font-medium font-mono" style={{ color: '#FFCF7B' }}>${fmt(activeItem.dayRate)}</span>
                    <span className="text-[10px] ml-1" style={{ color: '#555560' }}>per day</span>
                  </div>
                  <StatusBadge status={activeItem.status} />
                </div>

                {/* Specs */}
                <div className="flex flex-col mb-3">
                  {activeItem.specs.map(([key, val]) => (
                    <div key={key} className="flex justify-between py-1.5" style={{ borderBottom: '0.5px solid rgba(255,255,255,0.04)' }}>
                      <span className="text-[11px]" style={{ color: '#555560' }}>{key}</span>
                      <span
                        className="text-[11px] text-right"
                        style={{
                          color: val === 'In stock' ? '#4ABA82' : val === 'Limited' ? '#F0BA4A' : '#BDBDC8',
                          maxWidth: 110,
                        }}
                      >
                        {val}
                      </span>
                    </div>
                  ))}
                </div>

                {/* Compatibility */}
                <p className="text-[10px] font-medium uppercase tracking-widest mb-2" style={{ color: '#555560' }}>Works with</p>
                <div className="flex flex-col gap-1">
                  {activeItem.compatibility.map((c, i) => (
                    <div key={i} className="flex items-center gap-1.5 text-[11px]" style={{ color: '#9090A0' }}>
                      <span className="w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ background: c.color }} />
                      {c.label}
                    </div>
                  ))}
                </div>
              </>
            )}

            {/* ── Budget tab ── */}
            {contextTab === 'budget' && (
              <>
                <p className="text-[11px] font-medium mb-2" style={{ color: '#EAEAEA' }}>Daily breakdown</p>
                {(['camera', 'lenses', 'support', 'focus', 'video'] as GearCategory[]).map(cat => {
                  const total = packageItems[cat].reduce((s, id) => s + (getItem(id)?.dayRate ?? 0), 0)
                  return (
                    <div key={cat} className="flex justify-between py-1">
                      <span className="text-[11px] capitalize" style={{ color: '#666672' }}>{cat}</span>
                      <span className="text-[11px] font-mono" style={{ color: total > 0 ? '#9090A0' : '#444450' }}>
                        {total > 0 ? `$${fmt(total)}` : '—'}
                      </span>
                    </div>
                  )
                })}
                <div className="flex justify-between py-2 mt-1" style={{ borderTop: '0.5px solid rgba(255,255,255,0.08)' }}>
                  <span className="text-[11px] font-medium" style={{ color: '#EAEAEA' }}>Total / day</span>
                  <span className="text-[13px] font-medium font-mono" style={{ color: '#EAEAEA' }}>${fmt(totalDayRate)}</span>
                </div>

                <div className="mt-3 pt-3" style={{ borderTop: '0.5px solid rgba(255,255,255,0.06)' }}>
                  <p className="text-[11px] font-medium mb-2" style={{ color: '#EAEAEA' }}>{SHOOT_DAYS}-day estimate</p>
                  <div className="flex justify-between py-1">
                    <span className="text-[11px]" style={{ color: '#666672' }}>At day rate</span>
                    <span className="text-[11px] font-mono" style={{ color: '#9090A0' }}>${fmt(totalEstimate)}</span>
                  </div>
                  <div className="flex justify-between py-1">
                    <span className="text-[11px]" style={{ color: '#666672' }}>Approved budget</span>
                    <span className="text-[11px] font-mono" style={{ color: '#4ABA82' }}>${fmt(APPROVED_BUDGET_TOTAL)}</span>
                  </div>
                  <div className="flex justify-between py-1">
                    <span className="text-[11px]" style={{ color: '#666672' }}>Remaining</span>
                    <span className="text-[11px] font-mono" style={{ color: remaining >= 0 ? '#4ABA82' : '#E06B6B' }}>
                      {remaining >= 0 ? `$${fmt(remaining)}` : `-$${fmt(Math.abs(remaining))}`}
                    </span>
                  </div>
                </div>

                {/* Item statuses */}
                <div className="mt-3 pt-3" style={{ borderTop: '0.5px solid rgba(255,255,255,0.06)' }}>
                  <p className="text-[10px] font-medium uppercase tracking-widest mb-2" style={{ color: '#555560' }}>Item status</p>
                  {allPackageIds.map(id => {
                    const item = getItem(id)
                    if (!item) return null
                    return (
                      <div key={id} className="flex justify-between items-center py-1.5" style={{ borderBottom: '0.5px solid rgba(255,255,255,0.04)' }}>
                        <span className="text-[11px] truncate mr-2" style={{ color: '#9090A0', maxWidth: 100 }}>{item.name}</span>
                        <StatusBadge status={item.status} />
                      </div>
                    )
                  })}
                </div>
              </>
            )}
          </div>
        </aside>
      </div>
    </div>
  )
}
