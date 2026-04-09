# Altoscope — Brand Guidelines

Collaborative preproduction software for gear-intensive productions. Altoscope gives DPs, producers, and production coordinators one place to build technically validated gear packages, align on budget, and route requests to rental houses — without the email chains, spreadsheet versions, and prep-day surprises that slow every production down.

---

## Audience

**Primary ICP:** Tech-forward creative industry professionals, ages 25–45, with experience in video production. Roles include directors of photography, production coordinators, and producers working on non-unionized commercial, narrative, or documentary productions.

**Design tone:** Calm authority. Precise and considered — closer to DaVinci Resolve or Frame.io than to consumer SaaS. Not playful, not corporate. The interface should feel like a tool a DP would trust on prep day.

---

## Logo

The Altoscope mark is a nested arch — three concentric arches forming a single architectural symbol. It references framing, scope, and depth, which aligns with the product's purpose of framing and planning a production.

**Usage rules:**
- Minimum size: 24px height for the mark alone (fine strokes collapse below this)
- Clear space: equal to the cap-height of the wordmark on all sides
- Do not recolor, skew, or place on busy or patterned backgrounds
- Preferred on dark surfaces; light-surface version available

**Variants:**
- Mark only (icon use, favicons, app icons)
- Horizontal lockup (mark + wordmark, primary usage)

---

## Typography

**Typeface:** Aktiv Grotesk (Bold, Medium, Light)

Aktiv Grotesk is the sole typeface across all surfaces. It is highly legible at small sizes, neutral without being bland, and carries authority without feeling corporate-cold. Light weight should only be used at 24px and above.

### Type scale

| Token | Size | Weight | Line height | Usage |
|---|---|---|---|---|
| `text.display` | 28px | 500 | 1.2 | Page titles, production names |
| `text.heading` | 20px | 500 | 1.3 | Section headings, package names |
| `text.subheading` | 15px | 500 | 1.4 | Category labels, panel titles |
| `text.body` | 14px | 400 | 1.6 | Descriptions, notes, prose |
| `text.label` | 12px | 500 | 1.4 | Column headers, metadata, form labels |
| `text.caption` | 11px | 400 | 1.5 | Timestamps, counts, helper text |
| `text.data` | 13px | 400 mono | — | SKUs, prices, quantities, codes |

`text.data` uses a monospaced fallback (system-mono). All numeric and code-like values — day rates, SKUs, quantities — should use this style. It aligns columns and communicates precision.

---

## Color

### Brand palette

| Token | Hex | Usage |
|---|---|---|
| `color.bg.base` | `#18181A` | App background — Eerie Black |
| `color.bg.surface` | `#242428` | Cards, panels, elevated surfaces |
| `color.bg.overlay` | `#2E2E34` | Inputs, hover states, sidebars |
| `color.border.subtle` | `rgba(255,255,255,0.07)` | Dividers, section separators |
| `color.border.default` | `rgba(255,255,255,0.12)` | Card borders, input borders |
| `color.brand.navy` | `#1D2C59` | Brand accent — Delft Blue, hero moments |
| `color.interactive.default` | `#3D55A8` | Buttons, links, focus rings |
| `color.interactive.hover` | `#4D68C0` | Button hover state |
| `color.accent.sunset` | `#FFCF7B` | Highlights, key badges, send CTA — Sunset |
| `color.text.primary` | `#EAEAEA` | Primary text — Platinum |
| `color.text.secondary` | `#BDBDC8` | Body text, descriptions |
| `color.text.muted` | `#9090A0` | Labels, metadata |
| `color.text.subtle` | `#666672` | Captions, hints |
| `color.text.disabled` | `#555560` | Disabled states, placeholders |

**Sunset (`#FFCF7B`) is an accent only.** Reserve it for the single highest-priority CTA on a screen (typically "Send quote") and for key callout badges. Using it for general UI elements dilutes its impact.

**Delft Blue (`#1D2C59`) is a brand tone, not an interactive color.** Use `color.interactive.default` (`#3D55A8`) for all buttons, links, and focus rings. Reserve the deep navy for structural and brand moments (headers, illustrations, marketing).

### Semantic colors

| Token | Hex | Usage |
|---|---|---|
| `color.semantic.success` | `#4ABA82` | Confirmed, approved, in stock |
| `color.semantic.warning` | `#F0BA4A` | Budget warnings, soft flags |
| `color.semantic.danger` | `#E06B6B` | Gear conflicts, hard errors, unavailable |
| `color.semantic.info` | `#60A8D8` | Tooltips, neutral informational messages |

Semantic colors are intentionally de-saturated compared to typical UI palettes. This audience works in dark editing suites — loud status colors feel out of place and erode trust. Reserve the loudness for hard errors only.

### Rental quote status system

This is the most critical status flow in the product. Use these colors consistently across all status indicators, badges, and table rows.

| Status | Background | Text | Usage |
|---|---|---|---|
| `draft` | `#2C2C35` | `#9B9BAD` | Not yet sent to any rental house |
| `sent` | `#1A3260` | `#7AAEE8` | Sent to rental house, awaiting response |
| `quote_received` | `#1A3040` | `#5CB8D8` | Quote received, awaiting review |
| `approved` | `#1A4030` | `#4ABA82` | Approved by coordinator |
| `confirmed` | `#2A4020` | `#7AC84A` | Confirmed by rental house |
| `unavailable` | `#3A2020` | `#E06B6B` | Item not available |
| `over_budget` | `#3A2E10` | `#F0BA4A` | Item exceeds approved budget |

**Blue = in motion** (sent, received). **Green = resolved** (approved, confirmed). This maps to how crew think about a quote: you send it out (blue), it comes back (blue), it's locked (green). Red only for hard blockers.

---

## Components

### Buttons

Five variants — each with a specific job. Do not use interchangeably.

| Variant | Usage |
|---|---|
| **Primary** (blue) | Main action per screen — "Add to package", "Save" |
| **Secondary** (ghost surface) | Alternative actions — "Save draft", "Duplicate" |
| **Accent** (Sunset) | The one send/publish CTA — "Send quote". One per screen max. |
| **Ghost** | Cancel, dismiss, low-priority actions |
| **Danger** | Destructive actions only — "Remove item", "Delete package" |

Disabled state uses `opacity: 0.35` — the button stays recognizable as a button, just unavailable. Do not change the color for disabled states.

### Form inputs

- Default border: `rgba(255,255,255,0.10)` on `#2E2E34` background
- Focus ring: `box-shadow: 0 0 0 3px rgba(61,85,168,0.20)` with border `#3D55A8`
- Error state: border `rgba(224,107,107,0.60)`, helper text in `color.semantic.danger`
- Success state: border `rgba(74,186,130,0.50)`, helper text in `color.semantic.success`
- All form labels use `text.label` style, uppercase, letter-spacing 0.04em

### Status badges

Badges use a pill shape (`border-radius: 20px`) with a 6px colored dot, a semi-transparent background, and a thin border at 20% opacity of the text color. Always use the status color table above — do not invent new badge colors.

### Data tables (gear package lists)

- Row height: 44px minimum
- Hover state: `rgba(255,255,255,0.02)` background
- Active/selected row: `rgba(61,85,168,0.08)` background
- Column headers: `text.label` style, uppercase
- Item names: `text.body` weight 500 (`#EAEAEA`)
- SKUs and secondary info: `text.caption` style, below the item name
- Quantities and prices: `text.data` (monospace), right-aligned
- Category section headers collapse/expand — chevron indicator

---

## Voice & tone

- **Precise, not verbose.** Copy should read like a professional tool, not a consumer app. Fewer words, more specificity.
- **Never condescending.** The experience level system (Guided / Standard / Pro) changes defaults and noise, not capabilities. Guided users are not beginners — they may be experienced producers who are new to the tool.
- **Production-fluent.** Use industry terminology correctly: "day rate" not "daily price", "rental house" not "vendor", "package" not "kit" (in UI copy), "DP" not "cinematographer" in short-form contexts.
- **Error messages should explain, not apologize.** "Exceeds approved budget by $2,100" not "Something went wrong with your budget."

---

## Do / don't

| Do | Don't |
|---|---|
| Use Sunset as the send CTA — one per screen | Use Sunset for general highlights or multiple CTAs |
| Use monospace for all numeric data | Use proportional text for prices or quantities in tables |
| Use muted semantic colors for status | Use bright/saturated status colors |
| Keep the logo on dark backgrounds where possible | Place the logo on busy or patterned backgrounds |
| Use `text.label` uppercase for column headers | Use sentence case for column headers |
| Reserve red for hard blockers only | Use red for warnings or soft flags |
