import type { GearItem, PackageItems } from './types'

// ─── Mock gear catalog ────────────────────────────────────────────────────────
// In production this would be fetched from Supabase via the gear catalog tables.

export const CATALOG: GearItem[] = [
  {
    id: 'alexa35',
    name: 'ARRI ALEXA 35',
    sku: 'SKU-AR-ALEXA35',
    category: 'camera',
    dayRate: 1800,
    specSummary: '4.6K · LPL/PL · 17 stops',
    status: 'confirmed',
    specs: [
      ['Sensor',        '35mm ALEV 4'],
      ['Resolution',    '4.6K Open Gate'],
      ['Mount',         'LPL / PL'],
      ['Dynamic range', '17 stops'],
      ['Availability',  'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Cooke S7/i Full Frame' },
      { color: '#4ABA82', label: 'ARRI Signature Primes' },
      { color: '#F0BA4A', label: 'Leica M (needs adapter)' },
      { color: '#E06B6B', label: 'Canon EF (not recommended)' },
    ],
  },
  {
    id: 'venice2',
    name: 'Sony VENICE 2',
    sku: 'SKU-SN-VN2-8K',
    category: 'camera',
    dayRate: 1650,
    specSummary: '8.4K · PL/E · 15+ stops',
    status: 'draft',
    specs: [
      ['Sensor',        'Full Frame 8.6MP'],
      ['Resolution',    '8.6K Full Frame'],
      ['Mount',         'PL / E-mount'],
      ['Dynamic range', '15+ stops'],
      ['Availability',  'Check stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Cooke S4/i Primes' },
      { color: '#4ABA82', label: 'Zeiss Supreme Primes' },
      { color: '#F0BA4A', label: 'LPL (needs adapter)' },
    ],
  },
  {
    id: 'cooke-s7',
    name: 'Cooke S7/i Full Frame',
    sku: 'SKU-CK-S7FF-5PC',
    category: 'lenses',
    dayRate: 2400,
    specSummary: '5-lens set · LPL · FF',
    status: 'sent',
    specs: [
      ['Coverage',     'Full Frame+'],
      ['Mount',        'LPL'],
      ['Set',          '5-lens (18–135mm)'],
      ['T-stop',       'T2.0'],
      ['Availability', 'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'ALEXA 35' },
      { color: '#4ABA82', label: 'VENICE 2 (with LPL-E)' },
      { color: '#E06B6B', label: 'BMPCC (coverage issue)' },
    ],
  },
  {
    id: 'sig-primes',
    name: 'ARRI Signature Primes',
    sku: 'SKU-AR-SIGPX6',
    category: 'lenses',
    dayRate: 1800,
    specSummary: '6-lens set · LPL · FF',
    status: 'draft',
    specs: [
      ['Coverage',     'Full Frame'],
      ['Mount',        'LPL'],
      ['Set',          '6-lens (12–280mm)'],
      ['T-stop',       'T1.8–T2.8'],
      ['Availability', 'Limited'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'ALEXA 35' },
      { color: '#4ABA82', label: 'ALEXA Mini LF' },
      { color: '#F0BA4A', label: 'PL cameras (adapter req)' },
    ],
  },
  {
    id: 'oconnor',
    name: "OConnor 2575",
    sku: 'SKU-OC-2575-HD',
    category: 'support',
    dayRate: 420,
    specSummary: 'Fluid head · 75mm bowl',
    status: 'confirmed',
    specs: [
      ['Max load',    '25 kg'],
      ['Bowl',        '75mm'],
      ['Pan drag',    '0–10 steps'],
      ['Tilt range',  '±90°'],
      ['Availability','In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Most cinema cameras' },
      { color: '#4ABA82', label: 'ARRI ALEXA 35' },
      { color: '#4ABA82', label: 'Sony VENICE 2' },
    ],
  },
  {
    id: 'preston',
    name: 'Preston FIZ MDR-3',
    sku: 'SKU-PR-FIZ-MDR3',
    category: 'focus',
    dayRate: 480,
    specSummary: 'Wireless FIZ · 3-channel',
    status: 'draft',
    specs: [
      ['Channels',     '3 (F/I/Z)'],
      ['Range',        '300ft line-of-sight'],
      ['Motors',       '3x included'],
      ['Protocol',     'Preston'],
      ['Availability', 'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Most lens motors' },
      { color: '#4ABA82', label: 'Cine lenses (standard)' },
      { color: '#F0BA4A', label: 'Some photo lenses' },
    ],
  },
  {
    id: 'teradek',
    name: 'Teradek Bolt 6 XT 750',
    sku: 'SKU-TD-BOLT6-750',
    category: 'video',
    dayRate: 320,
    specSummary: '4K wireless TX · 750ft',
    status: 'draft',
    specs: [
      ['Range',        '750ft (230m)'],
      ['Resolution',   '4K 60fps'],
      ['Latency',      '< 1 ms'],
      ['Encryption',   'AES-256'],
      ['Availability', 'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'All SDI cameras' },
      { color: '#4ABA82', label: 'HDMI via adapter' },
      { color: '#F0BA4A', label: 'Older cameras (check SDI)' },
    ],
  },
]

// ─── Initial package state ────────────────────────────────────────────────────

export const INITIAL_PACKAGE: PackageItems = {
  camera:  ['alexa35'],
  lenses:  ['cooke-s7', 'sig-primes'],
  support: ['oconnor'],
  focus:   [],
  video:   [],
}

// ─── Budget constants ─────────────────────────────────────────────────────────

export const APPROVED_BUDGET_DAILY = 12_000
export const SHOOT_DAYS = 18
export const APPROVED_BUDGET_TOTAL = 95_000

// ─── Category display labels ──────────────────────────────────────────────────

export const CATEGORY_LABELS: Record<string, string> = {
  all:     'All',
  camera:  'Camera',
  lenses:  'Lenses',
  support: 'Support',
  focus:   'Focus',
  video:   'Video TX',
}
