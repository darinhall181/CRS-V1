# Brand Coverage Audit — August 4, 2026

Source: Notion "🧰 Brands" database (92 brands) cross-referenced against `pipeline/src/agents/spec_pipeline/product/` (plugins) and `pipeline/data/url_lists/` (discovery output).

## Current pipeline state

| Brand | Plugin | URL list | Notes |
|---|---|---|---|
| ARRI | camera | ✓ | In Notion ✓ |
| RED | camera | ✓ | **Not in Notion list** |
| Sony | camera | ✓ | URL list has only Burano/Venice/Venice 2 — FX line missing |
| Canon | camera + lens | discovery config only | In Notion ✓ |
| Blackmagic | camera | ✓ | **Not in Notion list** |
| Cooke | lens | ✓ (stale, Apr 2026 — no SP3/AP3) | **Not in Notion list** |
| Zeiss | lens | ✓ | In Notion ✓ |
| Angenieux | lens | ✓ | **Not in Notion list** |

Action: add RED, Blackmagic, Cooke, and Angenieux to the Notion database so it's the single source of truth. Panasonic is in neither Notion nor the pipeline despite being a weekly-brief priority brand — add it too.

## Batch plan

Rule of thumb: a batch = ~5 brands, each producing a plugin + url list + persisted specs before moving on. Order is by leverage for the compatibility engine (mount/media/power data), not alphabetical.

### Batch 0 — Refresh existing coverage (no new plugins, cheapest wins)
Re-run discovery for: **Sony** (add FX5/FX-series — pro site blocks crawling, may need manual URL adds), **Cooke** (SP3/AP3 + new Z-mount options), **Canon** (finish url list from discovery config), **ARRI, RED, Blackmagic, Zeiss, Angenieux** (staleness check).

### Batch 1 — Priority camera brands, new plugins
**Nikon** (Z cinema push; Cooke/Simmod now ship Z-mounts — cross-compat data needs Nikon bodies in DB), **Fujifilm** (GFX cinema ecosystem growing), **Panasonic** (Lumix/Varicam, priority brand), **DJI** (Ronin 4D + gimbals; drone line optional), **JVC** (pro camcorders — lighter).

### Batch 2 — Lens brands with real cine lines
**Sigma** (cine primes/zooms with AF), **Tamron**, **Samyang + Rokinon** (same optics, two storefronts — one plugin, two brand slugs), **Schneider** (Kreuznach cine), **SLR Magic**.

### Batch 3 — Budget/hybrid lens makers
**Viltrox**, **IRIX**, **ZY Optics**, **7Artisans**, **Voigtländer**. (Yongnuo, Lensbaby, Rollei lens lines — fold in if time allows; low RFQ relevance.)

### Batch 4 — Specialty/medium-format cameras
**Hasselblad**, **Phase One**, **Leica**, **Vision Research (Phantom)** (high-speed — common on commercial shoots), **iX Cameras**.

### Parked — needs schema/category decision first
- **Lighting (24 brands):** Aputure, Godox, Nanlite, Kino Flo, Litepanels, Profoto, Broncolor, Dedolight, Fillex, etc. Power compatibility (V-mount/Gold mount, wattage) is genuinely in-scope for productions, but requires a new `lighting` product category + spec-mapping rules. Decide before scraping any.
- **Accessories:** Manfrotto (tripod category exists!), GoPro, Westcott, Ikelite/Nauticam (underwater), Moment, Think Tank, Nanuk, etc. Manfrotto could slot into the existing tripod category as a quick pilot.
- **Out of scope for compatibility checking:** Mobile (Apple, Samsung, Google, Xiaomi, OPPO, OnePlus, HUAWEI, HMD, Motorola), printers (Epson, Konica Minolta), industrial/machine vision (Axis, Toshiba, Teledyne, Rencay, BuckEye, Bushnell, Leupold), film dev/large format (Linhof, Silvestri, Sinar, Minolta, Ricoh/Pentax point-and-shoots), drones-consumer (Parrot, Yuneec, Skydio), retailers (Filmtools, Bower, PromarkBRANDS). Keep in Notion, exclude from scraping audit.

## Verification-first workflow (guard against drift)

Most of the Notion list is not in the Altoscope DB yet, and the end state is Altoscope matching Notion. To keep every increment checkable rather than trusting bulk runs:

1. **Seed brands first, products later.** Insert brand rows into Supabase directly from the Notion export — mechanical, no scraping, easy to eyeball in one diff. This alone makes "what's missing" queryable in the app.
2. **One brand at a time within a batch.** Run discovery → extraction → normalize on a single brand, review the JSON output (url list + raw specs) before persist. The pipeline already stores `raw_value` verbatim from the manufacturer page, so every normalized spec is traceable to its source string — spot-check a handful per brand against the live product page.
3. **Persist is append-only** (upsert, never delete), so a bad run can't silently erase verified data, but review normalization mappings before persisting a new category since spec_mapping rules are shared per category_slug.
4. **Batch is "done" when:** url list reviewed, spot-checks pass, product count in DB matches url list count. Log it in this doc or Notion.

## Suggested Notion changes

Add properties to the Brands database so it doubles as the audit tracker:
- **Audit Batch** (select: 0–4, Parked, Out of scope)
- **Plugin exists** (checkbox)
- **URL list** (checkbox)
- **In DB** (checkbox)

Then the weekly gear brief can flag new products against batch status automatically.
