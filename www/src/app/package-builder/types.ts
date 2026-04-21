// ─── Enums ──────────────────────────────────────────────────────────────────

export type GearCategory = 'camera' | 'lenses' | 'support' | 'focus' | 'video'

export type PackageItemStatus =
  | 'draft'
  | 'sent'
  | 'quote_received'
  | 'approved'
  | 'confirmed'
  | 'unavailable'
  | 'over_budget'

export type ExperienceLevel = 'guided' | 'standard' | 'pro'

export type ContextTab = 'detail' | 'budget'

// ─── Gear catalog ─────────────────────────────────────────────────────────────

export interface CompatibilityNote {
  color: string
  label: string
}

export interface GearItem {
  id: string
  name: string
  sku: string
  category: GearCategory
  dayRate: number
  specSummary: string
  status: PackageItemStatus
  specs: [string, string][]
  compatibility: CompatibilityNote[]
}

// ─── Package state ────────────────────────────────────────────────────────────

export type PackageItems = Record<GearCategory, string[]>

// ─── Status badge config ──────────────────────────────────────────────────────

export interface StatusStyle {
  bg: string
  text: string
  dot: string
  label: string
}

export const STATUS_STYLES: Record<PackageItemStatus, StatusStyle> = {
  draft:          { bg: '#2C2C35', text: '#9B9BAD', dot: '#9B9BAD',  label: 'Draft' },
  sent:           { bg: '#1A3260', text: '#7AAEE8', dot: '#7AAEE8',  label: 'Sent' },
  quote_received: { bg: '#1A3040', text: '#5CB8D8', dot: '#5CB8D8',  label: 'Quote received' },
  approved:       { bg: '#1A4030', text: '#4ABA82', dot: '#4ABA82',  label: 'Approved' },
  confirmed:      { bg: '#2A4020', text: '#7AC84A', dot: '#7AC84A',  label: 'Confirmed' },
  unavailable:    { bg: '#3A2020', text: '#E06B6B', dot: '#E06B6B',  label: 'Unavailable' },
  over_budget:    { bg: '#3A2E10', text: '#F0BA4A', dot: '#F0BA4A',  label: 'Over budget' },
}

// ─── Budget helpers ───────────────────────────────────────────────────────────

export interface BudgetBreakdown {
  camera: number
  lenses: number
  support: number
  focus: number
  video: number
  totalPerDay: number
  totalEstimate: number
  approvedBudget: number
  remaining: number
}
