import type { GearItem, PackageItems } from './types'

// ─── Gear catalog ─────────────────────────────────────────────────────────────
// Image URLs sourced from manufacturer CDNs via the Altoscope scraping pipeline.

export const CATALOG: GearItem[] = [

  // ── Cameras ────────────────────────────────────────────────────────────────

  {
    id: 'alexa-mini-lf',
    name: 'ARRI ALEXA Mini LF',
    sku: 'K3.0004082',
    category: 'camera',
    dayRate: 1600,
    specSummary: '4.5K · LF · LPL/PL · 14 stops',
    status: 'confirmed',
    imageUrl: 'https://www.arri.com/resource/image/83566/landscape_ratio1x0_38/1920/737/e0d0c3b14d8089ad5b4420cf2a17ca8d/B78BBB86B355C816619CB86FAA162A51/cr-2019-alexa-mini-lf-product-image-1920x833.jpg',
    specs: [
      ['Sensor',        'Large Format ALEV 3'],
      ['Resolution',    '4.5K Open Gate'],
      ['Mount',         'LPL / PL'],
      ['Dynamic range', '14+ stops'],
      ['Availability',  'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Zeiss Supreme Primes (LPL)' },
      { color: '#4ABA82', label: 'ARRI Signature Primes (LPL)' },
      { color: '#F0BA4A', label: 'Canon CN-E (PL mount)' },
      { color: '#E06B6B', label: 'EF lenses (not recommended)' },
    ],
  },
  {
    id: 'venice2',
    name: 'Sony VENICE 2',
    sku: 'ILME-SB256',
    category: 'camera',
    dayRate: 1650,
    specSummary: '8.6K · PL/E · 15+ stops',
    status: 'sent',
    imageUrl: 'https://pro.sony/s3/2021/10/31115504/VENICE-2_hero-image_without-Netflix.png',
    specs: [
      ['Sensor',        'Full Frame 8.6MP'],
      ['Resolution',    '8.6K Full Frame'],
      ['Mount',         'PL / E-mount'],
      ['Dynamic range', '15+ stops'],
      ['Availability',  'Check stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Zeiss Supreme Primes (PL)' },
      { color: '#4ABA82', label: 'Canon CN-E PL primes' },
      { color: '#F0BA4A', label: 'LPL (adapter required)' },
    ],
  },
  {
    id: 'komodo-x',
    name: 'RED KOMODO-X 6K S35',
    sku: 'RD-KMDX-6K-S35',
    category: 'camera',
    dayRate: 850,
    specSummary: '6K · S35 · PL · 16+ stops',
    status: 'quote_received',
    imageUrl: 'https://images.red.com/og/komodo-x.jpg',
    specs: [
      ['Sensor',        'Super 35 6K'],
      ['Resolution',    '6144 × 3240'],
      ['Mount',         'PL'],
      ['Dynamic range', '16+ stops'],
      ['Availability',  'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Canon CN-E PL primes' },
      { color: '#4ABA82', label: 'Zeiss Supreme Primes (PL)' },
      { color: '#F0BA4A', label: 'LPL (needs adapter)' },
    ],
  },
  {
    id: 'v-raptor',
    name: 'RED V-RAPTOR 8K VV',
    sku: 'RD-VRPT-8K-VV',
    category: 'camera',
    dayRate: 1400,
    specSummary: '8K · VV · PL · 17+ stops',
    status: 'draft',
    imageUrl: 'https://images.red.com/og/v-raptor.jpg',
    specs: [
      ['Sensor',        'Vista Vision 8K'],
      ['Resolution',    '8192 × 4320'],
      ['Mount',         'DSMC3 (PL via adapter)'],
      ['Dynamic range', '17+ stops'],
      ['Availability',  'Limited'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'PL mount lenses (adapter)' },
      { color: '#4ABA82', label: 'Canon CN-E PL primes' },
      { color: '#F0BA4A', label: 'LPL (check adapter)' },
    ],
  },

  {
    id: 'canon-c300iii',
    name: 'Canon EOS C300 Mark III',
    sku: '4456C002',
    category: 'camera',
    dayRate: 1100,
    specSummary: '4K · S35 · PL/EF/EF-C · 16 stops',
    status: 'approved',
    imageUrl: undefined,
    specs: [
      ['Sensor',        'Super 35 Dual Gain Output'],
      ['Resolution',    '4K (4096×2160)'],
      ['Mount',         'PL / EF / EF-C'],
      ['Dynamic range', '16 stops'],
      ['Availability',  'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Canon CN-E primes (EF Cinema)' },
      { color: '#4ABA82', label: 'Zeiss Supreme Primes (PL)' },
      { color: '#4ABA82', label: 'Cine Servo zooms (EF)' },
      { color: '#F0BA4A', label: 'LPL (adapter required)' },
    ],
  },
  {
    id: 'canon-c500ii',
    name: 'Canon EOS C500 Mark II',
    sku: '9899B002',
    category: 'camera',
    dayRate: 1350,
    specSummary: '5.9K · FF · PL/EF · 15 stops',
    status: 'quote_received',
    imageUrl: undefined,
    specs: [
      ['Sensor',        'Full Frame 5.9K CMOS'],
      ['Resolution',    '5952×3140'],
      ['Mount',         'PL / EF / EF-C'],
      ['Dynamic range', '15+ stops'],
      ['Availability',  'Check stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Canon CN-E primes (EF Cinema)' },
      { color: '#4ABA82', label: 'Zeiss Supreme Primes (PL)' },
      { color: '#4ABA82', label: 'Canon CN-E zooms (EF)' },
      { color: '#F0BA4A', label: 'LPL (adapter required)' },
    ],
  },

  // ── Lenses ─────────────────────────────────────────────────────────────────

  {
    id: 'zeiss-supreme',
    name: 'Zeiss Supreme Prime Set',
    sku: '2198-837',
    category: 'lenses',
    dayRate: 2200,
    specSummary: '6-lens set · PL/LPL · FF',
    status: 'confirmed',
    imageUrl: 'https://www.zeiss.com/content/dam/pno/images/cinematography/products/supreme-prime-lenses/footage/vlcsnap-2025-12-15-15h14m53s793.png',
    specs: [
      ['Coverage',     'Full Frame'],
      ['Mount',        'PL / LPL'],
      ['Set',          '6-lens (15–200mm)'],
      ['T-stop',       'T1.5–T2.2'],
      ['Availability', 'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'ARRI ALEXA 35 (LPL)' },
      { color: '#4ABA82', label: 'Sony VENICE 2 (PL)' },
      { color: '#4ABA82', label: 'Blackmagic URSA Cine (PL/LPL)' },
    ],
  },
  {
    id: 'cn-e35',
    name: 'Canon CN-E 35mm T1.5 L F',
    sku: '9139B001',
    category: 'lenses',
    dayRate: 380,
    specSummary: '35mm · EF · T1.5 · FF',
    status: 'approved',
    imageUrl: 'https://s7d1.scene7.com/is/image/canon/9139B001_cn-e35mm-t1.5-l-f_primary?fmt=webp-alpha&wid=800',
    specs: [
      ['Focal length',  '35mm'],
      ['T-stop',        'T1.5'],
      ['Mount',         'EF Cinema'],
      ['Coverage',      'Full Frame'],
      ['Availability',  'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Sony VENICE 2 (E-mount adapter)' },
      { color: '#4ABA82', label: 'Canon EOS C-series' },
      { color: '#F0BA4A', label: 'ALEXA 35 (EF-PL adapter)' },
    ],
  },
  {
    id: 'cn-e50',
    name: 'Canon CN-E 50mm T1.3 L F',
    sku: '6570B001',
    category: 'lenses',
    dayRate: 380,
    specSummary: '50mm · EF · T1.3 · FF',
    status: 'approved',
    imageUrl: 'https://s7d1.scene7.com/is/image/canon/6570B001_cn-e50mm-t1.3-l-f_primary?fmt=webp-alpha&wid=800',
    specs: [
      ['Focal length',  '50mm'],
      ['T-stop',        'T1.3'],
      ['Mount',         'EF Cinema'],
      ['Coverage',      'Full Frame'],
      ['Availability',  'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Sony VENICE 2 (E-mount adapter)' },
      { color: '#4ABA82', label: 'Canon EOS C-series' },
      { color: '#F0BA4A', label: 'ALEXA 35 (EF-PL adapter)' },
    ],
  },

  {
    id: 'cn-e24',
    name: 'Canon CN-E 24mm T1.5 L F',
    sku: '6569B001',
    category: 'lenses',
    dayRate: 350,
    specSummary: '24mm · EF · T1.5 · FF',
    status: 'approved',
    imageUrl: 'https://s7d1.scene7.com/is/image/canon/6569B001_cn-e24mm-t1.5-l-f_primary?fmt=webp-alpha&wid=800',
    specs: [
      ['Focal length',  '24mm'],
      ['T-stop',        'T1.5'],
      ['Mount',         'EF Cinema'],
      ['Coverage',      'Full Frame'],
      ['Availability',  'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Canon EOS C300 Mark III' },
      { color: '#4ABA82', label: 'Canon EOS C500 Mark II' },
      { color: '#F0BA4A', label: 'Sony VENICE 2 (E-mount adapter)' },
      { color: '#F0BA4A', label: 'ALEXA Mini LF (EF-PL adapter)' },
    ],
  },
  {
    id: 'cn-e85',
    name: 'Canon CN-E 85mm T1.3 L F',
    sku: '6571B001',
    category: 'lenses',
    dayRate: 380,
    specSummary: '85mm · EF · T1.3 · FF',
    status: 'approved',
    imageUrl: 'https://s7d1.scene7.com/is/image/canon/6571B001_cn-e85mm-t1.3-l-f_primary?fmt=webp-alpha&wid=800',
    specs: [
      ['Focal length',  '85mm'],
      ['T-stop',        'T1.3'],
      ['Mount',         'EF Cinema'],
      ['Coverage',      'Full Frame'],
      ['Availability',  'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Canon EOS C300 Mark III' },
      { color: '#4ABA82', label: 'Canon EOS C500 Mark II' },
      { color: '#F0BA4A', label: 'Sony VENICE 2 (E-mount adapter)' },
      { color: '#F0BA4A', label: 'ALEXA Mini LF (EF-PL adapter)' },
    ],
  },
  {
    id: 'cn-e135',
    name: 'Canon CN-E 135mm T2.2 L F',
    sku: '8326B001',
    category: 'lenses',
    dayRate: 380,
    specSummary: '135mm · EF · T2.2 · FF',
    status: 'draft',
    imageUrl: 'https://s7d1.scene7.com/is/image/canon/8326B001_cn-e135mm-t2.2-l-f_primary?fmt=webp-alpha&wid=800',
    specs: [
      ['Focal length',  '135mm'],
      ['T-stop',        'T2.2'],
      ['Mount',         'EF Cinema'],
      ['Coverage',      'Full Frame'],
      ['Availability',  'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Canon EOS C300 Mark III' },
      { color: '#4ABA82', label: 'Canon EOS C500 Mark II' },
      { color: '#F0BA4A', label: 'Sony VENICE 2 (E-mount adapter)' },
      { color: '#F0BA4A', label: 'ALEXA Mini LF (EF-PL adapter)' },
    ],
  },
  {
    id: 'cn-e-14-35',
    name: 'Canon CN-E 14-35mm T1.7 L S',
    sku: '6154C007',
    category: 'lenses',
    dayRate: 550,
    specSummary: '14-35mm · EF · T1.7 · FF',
    status: 'confirmed',
    imageUrl: 'https://s7d1.scene7.com/is/image/canon/6154C007_cn-e14-35mm-t1-7-l-s_primary?fmt=webp-alpha&wid=800',
    specs: [
      ['Focal length',  '14–35mm'],
      ['T-stop',        'T1.7'],
      ['Mount',         'EF Cinema'],
      ['Coverage',      'Full Frame'],
      ['Availability',  'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Canon EOS C300 Mark III' },
      { color: '#4ABA82', label: 'Canon EOS C500 Mark II' },
      { color: '#F0BA4A', label: 'Sony VENICE 2 (E-mount adapter)' },
      { color: '#E06B6B', label: 'ALEXA Mini LF (not recommended)' },
    ],
  },
  {
    id: 'cn-e-30-105',
    name: 'Canon CN-E 30-105mm T2.8 L S',
    sku: '7623B002',
    category: 'lenses',
    dayRate: 450,
    specSummary: '30-105mm · EF · T2.8 · FF',
    status: 'sent',
    imageUrl: 'https://s7d1.scene7.com/is/image/canon/7623B002_cn-e30-105mm-t2.8-l-s_primary?fmt=webp-alpha&wid=800',
    specs: [
      ['Focal length',  '30–105mm'],
      ['T-stop',        'T2.8'],
      ['Mount',         'EF Cinema'],
      ['Coverage',      'Full Frame'],
      ['Availability',  'Check stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Canon EOS C300 Mark III' },
      { color: '#4ABA82', label: 'Canon EOS C500 Mark II' },
      { color: '#F0BA4A', label: 'Sony VENICE 2 (E-mount adapter)' },
      { color: '#E06B6B', label: 'ALEXA Mini LF (not recommended)' },
    ],
  },
  {
    id: 'cine-servo-17-120',
    name: 'Canon Cine Servo 17-120mm T2.95',
    sku: '9785B001',
    category: 'lenses',
    dayRate: 680,
    specSummary: '17-120mm · EF · T2.95 · S35',
    status: 'draft',
    imageUrl: 'https://s7d1.scene7.com/is/image/canon/9785B001_cine-servo-17-120mm-t2.95-3.9-ef_primary?fmt=webp-alpha&wid=800',
    specs: [
      ['Focal length',  '17–120mm'],
      ['T-stop',        'T2.95–T3.9'],
      ['Mount',         'EF'],
      ['Coverage',      'Super 35'],
      ['Weight',        '2.9kg'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Canon EOS C300 Mark III' },
      { color: '#4ABA82', label: 'Canon EOS C500 Mark II' },
      { color: '#F0BA4A', label: 'RED KOMODO-X (EF adapter)' },
      { color: '#E06B6B', label: 'ALEXA Mini LF (not recommended)' },
    ],
  },

  // ── Support ────────────────────────────────────────────────────────────────

  {
    id: 'arri-mb20',
    name: 'ARRI MB-20 II Matte Box',
    sku: 'K2.52025.0',
    category: 'support',
    dayRate: 180,
    specSummary: '4×5.65 · clip-on/bridge',
    status: 'confirmed',
    imageUrl: 'https://www.arri.com/resource/image/44758/landscape_ratio1x0_38/1920/737/2d2b8e1b76ea338aa41d0c2f798d8a92/A5AFFED35C52EFF6C61448D6079BF9CA/teaser-bild.jpg',
    specs: [
      ['Filter stage',  '4×5.65"'],
      ['Rotation',      '±85° front stage'],
      ['Mounting',      'Clip-on / 15mm / 19mm'],
      ['Flags',         '2× included'],
      ['Availability',  'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Most cinema cameras' },
      { color: '#4ABA82', label: 'ARRI ALEXA 35' },
      { color: '#4ABA82', label: 'Sony VENICE 2' },
    ],
  },

  // ── Focus ──────────────────────────────────────────────────────────────────

  {
    id: 'arri-wcu4',
    name: 'ARRI WCU-4',
    sku: 'K2.47012.0',
    category: 'focus',
    dayRate: 320,
    specSummary: 'Wireless FIZ · 3-channel',
    status: 'confirmed',
    imageUrl: 'https://www.arri.com/resource/image/44758/landscape_ratio1x0_38/1920/737/2d2b8e1b76ea338aa41d0c2f798d8a92/A5AFFED35C52EFF6C61448D6079BF9CA/teaser-bild.jpg',
    specs: [
      ['Channels',     '3 (F/I/Z)'],
      ['Range',        '100m line-of-sight'],
      ['Display',      '3.5" touchscreen'],
      ['Protocol',     'ARRI LCS / LBUS'],
      ['Availability', 'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'ARRI ALEXA 35 (native)' },
      { color: '#4ABA82', label: 'Most LBUS-compatible rigs' },
      { color: '#F0BA4A', label: 'Non-ARRI cameras (adapter)' },
    ],
  },

  // ── Video TX ───────────────────────────────────────────────────────────────

  {
    id: 'teradek-bolt4k',
    name: 'Teradek Bolt 4K LT 750',
    sku: '10-2496',
    category: 'video',
    dayRate: 295,
    specSummary: '4K wireless TX · 750ft',
    status: 'draft',
    imageUrl: 'https://cdn.shopify.com/s/files/1/0095/4332/files/Preview_Image_ad88f7c2-4df6-44b9-82b7-d07d02f9694d.png?v=1706029569',
    specs: [
      ['Range',        '750ft (230m)'],
      ['Resolution',   '4K 60fps'],
      ['Latency',      '< 1 ms'],
      ['Encryption',   'AES-256'],
      ['Availability', 'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'All SDI cameras' },
      { color: '#4ABA82', label: 'ARRI ALEXA 35' },
      { color: '#F0BA4A', label: 'HDMI via adapter' },
    ],
  },
  {
    id: 'smallhd-cine7',
    name: 'SmallHD Cine 7',
    sku: 'MON-CINE7-BOLT6RX',
    category: 'video',
    dayRate: 220,
    specSummary: '7" · 1920×1200 · Bolt 6 RX',
    status: 'draft',
    imageUrl: 'http://smallhd.com/cdn/shop/files/Preview-Image.png?v=1705608080',
    specs: [
      ['Screen',       '7" IPS 1920×1200'],
      ['Nits',         '2500 nit'],
      ['Wireless',     'Bolt 6 RX built-in'],
      ['Inputs',       '12G SDI / HDMI'],
      ['Availability', 'In stock'],
    ],
    compatibility: [
      { color: '#4ABA82', label: 'Teradek Bolt 6 ecosystem' },
      { color: '#4ABA82', label: 'Any SDI/HDMI camera' },
      { color: '#F0BA4A', label: 'Bolt 4K (different system)' },
    ],
  },
]

// ─── Initial package state ────────────────────────────────────────────────────

export const INITIAL_PACKAGE: PackageItems = {
  camera:  ['alexa-mini-lf'],
  lenses:  ['zeiss-supreme', 'cn-e35'],
  support: ['arri-mb20'],
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
