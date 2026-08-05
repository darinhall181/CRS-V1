# Gear Announcement Brief — Week of July 27 – August 3, 2026

Quiet week for hardware. No new camera bodies or lens lines from priority brands — the news is two mount-compatibility releases, which matter more to Altoscope's compatibility matrix than a typical product drop would.

## New this week

**Cooke SP3 & AP3 — Nikon Z-mount option** (Lens ecosystem)
- Announced: July 28, 2026
- Cooke's SP3 full-frame spherical primes (6 lenses, 18–100mm) and AP3 1.5x anamorphic primes (35/50/85mm, T2.4) now offer a user-interchangeable Nikon Z-mount alongside E/RF/L. Z-mount versions ship August 2026; existing owners can buy the mount (~£414).
- Official page: https://cookeoptics.com/lenses/ (SP3/AP3 product pages under cookeoptics.com/lens/)
- Coverage: **brand covered, product not yet scraped** — `cooke` lens plugin exists, but `cooke_lens_urls.json` (8 URLs, discovered 2026-04-09) has no SP3 or AP3 entries at all. Re-run Cooke discovery; the mount-options field on those pages is exactly the compatibility data Altoscope needs.

**Simmod 4-in-1 ARRI PL Lens Adapter** (Accessory — lens mount adapter)
- Released: July 29, 2026, $189, shipping now
- Mechanical PL adapter with user-swappable camera-side mounts: Sony E, Canon RF, Nikon Z, Leica L. One SKU covers four mirrorless systems for PL glass. No support foot (relevant for heavy lenses).
- Official page: https://www.simmodlens.com/
- Coverage: **brand has no plugin** — no adapter/accessory category in the pipeline either (only camera/lens/tripod exist).

**Laowa Aksen 1-5X & 5-10X Ultra Macro series** (Lens — specialty macro, lower priority)
- Announced: July 31, 2026 (via Newsshooter). Extreme-magnification macro primes; niche for commercial tabletop/product work.
- Coverage: **brand has no plugin.** Non-priority brand — noting for completeness only.

## Just outside the window (context)

Sony FX5 was announced July 22 (previous week's news) but ships mid-August: 5K full-frame stacked sensor, 3:2 open gate, internal 16-bit X-OCN RAW, triple base ISO (800/4000/12800), E-mount, ~750 g. Official: https://pro.sony (Cinema Line). Coverage: **brand covered, product not yet scraped** — `sony_camera_urls.json` holds only Burano/Venice 2/Venice (note in file: "Sony pro site blocks automated crawling"), so the whole FX line is absent. Worth adding the FX5 URL manually when it goes live.

## Compatibility-relevant firmware/ecosystem news

- Nothing that changes mount protocols or media support. Blackmagic Camera 10.2.1 (July 31) is H.264/H.265 recording/playback fixes for URSA Broadcast G2 only — no schema impact.

## Notes

- ARRI, RED, Canon Cinema EOS, Panasonic, Fujifilm, Zeiss, Angenieux, Sigma, Fujinon, Leitz: no in-window announcements found. Canon is rumored to announce a compact Cinema EOS body around September/IBC — expect a busier cycle then.
- Accessory brands (Preston, Teradek, SmallHD, Anton Bauer, Core SWX, DJI Ronin, Tilta): nothing in-window.

## Sources

- [CineD — Cooke SP3 and AP3 Lenses Now Available for Nikon Z Mount](https://www.cined.com/cooke-sp3-and-ap3-lenses-now-available-for-nikon-z-mount/)
- [Newsshooter — Cooke SP3 & AP3 mirrorless lenses now available in Nikon Z-mount](https://www.newsshooter.com/2026/07/28/cooke-sp3-ap3-mirrorless-lenses-now-available-in-nikon-z-mount/)
- [CineD — Simmod 4-in-1 ARRI PL Lens Adapter Released](https://www.cined.com/simmod-4-in-1-arri-pl-lens-adapter-with-interchangeable-mount-released/)
- [Newsshooter — Simmod Lens 4-in-1 ARRI PL Lens Adapter Set](https://www.newsshooter.com/2026/07/29/simmod-lens-4-in-1-arri-pl-lens-adapter-set/)
- [Newsshooter — Laowa Aksen 1-5X & 5-10X Ultra Macro Series](https://www.newsshooter.com/2026/07/31/laowa-aksen-1-5x-5-10x-ultra-macro-series/)
- [CineD — Sony FX5 Announced](https://www.cined.com/sony-fx5-announced-full-frame-5k-open-gate-internal-x-ocn-raw-three-base-isos-4k-240p/)
- [Newsshooter — Blackmagic Camera 10.2.1 Update](https://www.newsshooter.com/2026/07/31/blackmagic-camera-10-2-1-update/)
