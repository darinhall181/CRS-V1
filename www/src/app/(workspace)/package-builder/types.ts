// ─── Enums ────────────────────────────────────────────────────────────────────

export type GearCategory = 'camera' | 'lenses' | 'support' | 'focus' | 'video'

export const GEAR_CATEGORY_LABELS: Record<GearCategory, string> = {
  camera: 'Camera',
  lenses: 'Lenses',
  support: 'Support',
  focus: 'Focus / AC',
  video: 'Video / Monitoring',
}

export type PackageItemStatus =
  | 'draft'
  | 'sent'
  | 'quote_received'
  | 'approved'
  | 'confirmed'
  | 'unavailable'
  | 'over_budget'

export type ContextTab = 'detail' | 'budget' | 'notes' | 'history'

// ─── Gear catalog ─────────────────────────────────────────────────────────────
// Sourced from the real `product` table (see lib/db/queries.ts getProducts), with
// day rates overlaid from rental_house_inventory where a real quote exists — see
// lib/db/queries.ts getRentalHouseInventory. Most catalog items don't have a real
// vendor row yet, so `rate.source` tells the UI (and the user) whether a number is
// a real DaVinci Rentals rate or a rough estimate.

export interface GearRate {
  dayRate: number
  weekRate: number | null
  source: "vendor" | "estimate"
  vendorName?: string
  quantityOnHand?: number | null
}

export interface GearItem {
  id: string
  slug: string
  name: string
  sku: string
  category: GearCategory
  brandName: string
  imageUrl: string | null
  rate: GearRate
}

// ─── Package line items ───────────────────────────────────────────────────────
// One row in the builder grid. References a GearItem by id.

export interface PackageLineItem {
  id: string // line item id (client-generated for the in-memory demo)
  gearId: string
  qty: number
  days: number
  status: PackageItemStatus
  notesCount: number
}

// ─── Package comments ──────────────────────────────────────────────────────────
// Package-scoped (see package_comments — T0008), not per-line-item: one thread
// per package, matching the Notes tab's actual UI (a sibling of Detail/Budget,
// not gated behind a selected line).

export interface PackageComment {
  id: string
  body: string
  createdAt: string // ISO — formatted client-side, same pattern as `updatedAt`/formatSavedAt
  updatedAt: string | null // ISO — non-null once edited; renders "(edited)" — see T0025
  authorId: string
  authorName: string
  mentionedUserIds: string[]
}

export interface MentionableUser {
  id: string
  name: string
}

// ─── Package events (T0025) ─────────────────────────────────────────────────
// Backs the Package Builder "History" tab. `kind` + `payload` stay generic on
// purpose (see schema.ts's packageEvents comment) — the client just knows how
// to render the handful of kinds the server actually writes today.

export type PackageEventKind = "item_added" | "item_qty_updated" | "item_removed" | "comment_added"

export interface PackageEvent {
  id: string
  kind: PackageEventKind | string
  payload: Record<string, unknown>
  createdAt: string
  actorName: string | null
}

// ─── Status badge config ──────────────────────────────────────────────────────

export interface StatusStyle {
  bg: string
  text: string
  dot: string
  label: string
}

export const STATUS_STYLES: Record<PackageItemStatus, StatusStyle> = {
  draft:          { bg: 'var(--status-draft-bg)',          text: 'var(--status-draft-text)',          dot: 'var(--status-draft-text)',          label: 'Draft' },
  sent:           { bg: 'var(--status-sent-bg)',           text: 'var(--status-sent-text)',           dot: 'var(--status-sent-text)',           label: 'Sent' },
  quote_received: { bg: 'var(--status-quotereceived-bg)',  text: 'var(--status-quotereceived-text)',  dot: 'var(--status-quotereceived-text)',  label: 'Quote received' },
  approved:       { bg: 'var(--status-approved-bg)',       text: 'var(--status-approved-text)',       dot: 'var(--status-approved-text)',       label: 'Approved' },
  confirmed:      { bg: 'var(--status-confirmed-bg)',      text: 'var(--status-confirmed-text)',      dot: 'var(--status-confirmed-text)',      label: 'Confirmed' },
  unavailable:    { bg: 'var(--status-unavailable-bg)',    text: 'var(--status-unavailable-text)',    dot: 'var(--status-unavailable-text)',    label: 'Unavailable' },
  over_budget:    { bg: 'var(--status-overbudget-bg)',     text: 'var(--status-overbudget-text)',     dot: 'var(--status-overbudget-text)',     label: 'Over budget' },
}
