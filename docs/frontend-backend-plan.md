# Frontend ↔ Backend Connection Plan

*Written 2026-08-08. The big-picture map for connecting the redesigned frontend surfaces
(Storefront, Package Builder, DP Profile, Rental House Map, Login, RFQ) to the existing
Drizzle/Neon backend. Companion task files: `docs/tasks/T0013`–`T0032`.*

---

## 1. Where the project actually stands

**Backend & data: strong.** The Drizzle schema (`www/src/lib/db/schema.ts`) is a
well-normalized catalog + pre-production planning model: brand → product → spec EAV chain,
compatibility axes, kit templates, and the full productions layer (companies → productions →
packages → package_items) with a real quote workflow enum
(`draft → sent → quote_received → approved → confirmed`). Rental houses, their locations,
inventory, and per-item quotes all have tables. The scraping pipeline feeds cameras + lenses.

**Frontend: one real surface plus scaffolding.** The Package Builder is the only screen wired
end-to-end (server component → `queries.ts` → client component → server actions →
`package_items`, with optimistic UI — T0003/T0005). `/gear` is a basic browse grid. `/login`
works but is unstyled shadcn-default. `/compatibility-checker` exists. Everything else —
storefront redesign, profile, map, RFQ — exists only as high-fidelity HTML design prototypes.

**The established connection pattern (keep it — it's the right one):**

```
schema.ts (Drizzle tables, mirrors Neon)
  → queries.ts (typed async functions)
    → (app)/*/page.tsx (Server Component fetches, no REST layer)
      → *-client.tsx (Client Component, interactivity only)
        → actions.ts ("use server" mutations + revalidatePath)
```

There is no API layer to build. "Connecting the frontend to the backend" in this codebase
means: for each screen, write the queries, hand the data to a page server component, keep
interactivity in a client component, and route mutations through server actions. Every batch
below is an application of that one pattern.

**Known shims to retire:** `DEMO_PRODUCTION_ID` (page.tsx), `DEMO_USER_ID` (actions.ts),
middleware auth gate disabled (T0012). These are the first things the foundations batch fixes,
because every subsequent screen needs a real session and a real "current production."

---

## 2. Neon: what we have vs. what the screens need

Live introspection from this sandbox wasn't possible (outbound Postgres is blocked), so this
is based on `schema.ts`, `supabase/migrations/`, and the seeding records in T0004/T0005 —
which confirm the productions layer is pushed and seeded on the dev branch
(`br-super-base-am9e7j58`: Harpeth Valley Studios / Top Gun Maverick / Camera Package /
4 package_items, Darin as owner+coordinator). **Worth one `bun run db:studio` pass to
confirm** the gaffer enum migration is applied and `rental_house*` tables have the
davinci-rentals rows the Package Builder reads.

**Source of truth — DECIDED 2026-08-08:** the database is Neon and `schema.ts` is
authoritative; migrations are generated from it (`drizzle-kit generate` → `db:push`).
`supabase/migrations/` predates the Neon move and is historical reference only. CLAUDE.md
now says so. Residual caveat: branch drift exists (this `develop` working tree is slightly
behind other branches), so before the migration-heavy batches (profile, map, RFQ), diff
`schema.ts` against the live Neon branch once (`db:studio`) to confirm they agree.

### Gap table — every screen vs. the schema

| Screen needs | Have in schema? | Gap / task |
|---|---|---|
| Products, categories, specs, images, search | ✅ full chain | — |
| Day/week rates per rental house | ✅ `rental_house_inventory` | sparse data only (davinci-rentals); estimates fallback exists |
| Package + line items + status workflow | ✅ `packages`, `package_items` | — |
| Per-house quotes per item | ✅ `package_item_quote` | item-scoped only; no quote *document* (see RFQ row) |
| Production roles | ✅ `production_members` (dp/coordinator/producer/gaffer + department) | UI never reads it → T0017 |
| Company roles | ✅ `company_members` (owner/admin/member) | same |
| **Rental-house-side users** | ❌ nothing links a user to a rental house | **`rental_house_members` — required for the RFQ dual view** → T0031 |
| DP profile (bio, location, union, availability, verified) | ❌ `users` has name/email/avatar only | new profile tables → T0029 |
| Owned kit w/ day rates, credits, DP rates, insurance docs, house accounts, regular crew | ❌ none | T0029 |
| Saved items / hearts (storefront) | ❌ | small `saved_product` table → T0023 |
| Star ratings (storefront cards) | ❌ no ratings source anywhere | **defer** — render without ratings until a data source exists |
| Geo coordinates for map pins | ❌ `rental_house_location` has address text only | add lat/lng + seed → T0027 |
| Package-match % per house (map cards) | ✅ computable: package_items × rental_house_inventory | query work, no schema change → T0028 |
| Onboarding: workspace type, profession, home market, referral, rate band | ❌ (`experience_level` exists on users) | `users` columns + minimal `user_profile` → T0035 |
| Google OAuth sign-in | ❌ email/password only | Better Auth social provider config → T0018 |
| RFQ document: header, status, hold expiry, revisions, two parties | ❌ quotes are per-item rows | quote-document layer → T0031 |
| Line substitutions, house-added lines, sub-rental source, margin | ❌ | T0031 |
| COI / insurance docs with coverage fields | ❌ | T0029 (user docs) + T0031 (production COI on quote) |
| Activity thread + timeline events | ❌ (T0008 comments still open) | T0025 (comments/change log), T0031 (RFQ thread) |
| Notes tab on package builder | ❌ T0008 open | T0025 |

**The deliberate non-goal:** the inventory workbook's schema map is right — there is no
*asset* layer (serials, condition, bins, real availability), and that is correct **as long as
Altoscope is the pre-production surface that talks to rental houses, not the house's system
of record**. Houses run RTPro/Flex/Current RMS; that market has brutal switching costs. Every
screen in this plan works at catalog + reference-rate granularity. The one place the line
gets thin is the RFQ rental-house view ("2 in yard · 1 out until Sep 6") — build that as
house-entered quote data (they type it), not as a live inventory system we own. This is the
single most important scoping decision in the plan; revisit it deliberately, not by accident.

---

## 3. Roles → views (the planning base you asked for)

Three role systems already exist in the schema; one is missing:

1. `users.app_role` — platform-level (user/admin). Server-controlled, can't be self-granted. ✅
2. `company_members.role` — owner / admin / member. ✅
3. `production_members.role` — **dp / coordinator / producer / gaffer** (+ `department`
   scoping for gaffer). ✅ Nothing in the UI reads it yet.
4. **Rental-house membership — missing.** The RFQ screen's whole premise is one document,
   two audiences. Until a user can *be* a rental-house agent, the "Rental house" view can
   only be a demo toggle. → T0031.

The onboarding handoff (added 2026-08-08) layers a dimension *above* all of these:
`workspace_type` — production · rental house · **hobbyist** — chosen at step 1 and driving
routing ever after. Hobbyists have no company, no production, no memberships; every
role-aware surface must tolerate all-null roles (T0017's context already returns them).
Onboarding also captures a `profession` (10 values: dp, photographer, videographer,
1st AC, producer, coordinator, gaffer, dit, rental, other) — deliberately *wider* than and
separate from the `production_role` authorization enum; the four that map, map, the rest
stay descriptive. → T0035.

Role × surface matrix (what each role sees — from the mockups + RFQ role-switch spec):

| Surface | DP | Coordinator | Producer | Gaffer | Rental house agent |
|---|---|---|---|---|---|
| Storefront/browse | full | full | full | full (dept-filtered default) | n/a (different home: incoming RFQs) |
| Package Builder | build/edit | build/edit + **Send quote** | budget view, approval actions | own department's group | n/a |
| RFQ | comment | production view | production view + approve | — | **house view: line edit menu, inventory col, margin panel** |
| DP Profile | own, full (rates visible) | public view | public view — **rates hidden until quote request** | public view | public view + owner-operator kit (avoid double-quoting) |
| Map | full | full | full | full | n/a |

Implementation shape (T0017): one `getViewerContext()` server helper that resolves
session → user → production membership (+ future house membership) once per request, passed
down as props. Role logic lives in server components (what data is even fetched), not
sprinkled through client components as `if (role)` — producers not receiving DP rate data
is a *query-level* rule, not a CSS-hidden one. That's the future-proofing that matters:
authorization decided where the data is fetched.

The RFQ prototype's role *switch* stays exactly as designed for development/demo, but per its
own README: in production, role comes from the authenticated user's org, never a toggle.

---

## 4. The core workflow, verified against the schema

The full circle (grounded in the Ohio research: houses split into self-serve e-commerce vs
high-touch quote-on-request — Altoscope's RFQ flow is precisely the bridge between those two
worlds):

```
BROWSE (storefront)          BUILD (package builder)         QUOTE (RFQ)                    CLOSE
gear/houses discovery   →    assemble by department     →    send to house(s)          →    approve → confirmed
                             check vs approved budget        house revises: subs,           hold → reservation
                             compatibility checks            adds, holds, margin
                             package_items: draft            status: sent →                 approved → confirmed
                                                             quote_received
```

The `package_item_status` enum already models this end-to-end — the workflow is *designed*
in the DB and simply has no UI past "draft." That's the strongest possible signal that the
batches below are wiring work, not invention. Two workflow gaps the enum doesn't cover
(both land in T0031): a quote-*document* status distinct from item status (a revision may
touch 6 of 38 lines), and hold expiry (`Extend hold 48 hrs` needs a timestamp to extend).

**And the circle doesn't close at "confirmed":** per the 2026-08-08 scope decision,
Altoscope also hosts the monetary transaction between the production studio and the rental
house. That's a post-Batch-6 layer (invoice → payment → payout riding on an approved RFQ —
scoped in T0033), but it shapes Batch 6 now: the RFQ document is the anchor a payment
attaches to, so approval must lock pricing immutably (snapshot totals on the rfq row at
approval, not derived live) — a payment can never reference a moving number.

---

## 5. Build order — six batches, each independently shippable

Dependency logic: foundations first (everything needs session + tokens + shell), then the
screens in ascending schema-risk order — restyles of existing data before new-table work.
Full details live in the task files; this is the map.

**Batch 0 · Foundations — T0013–T0017, exit gate T0034** *(unblocks everything)*
Session wiring (kill `DEMO_USER_ID`, then `DEMO_PRODUCTION_ID`), re-enable middleware,
elevation design tokens into `globals.css`, app shell/global nav per the mockups,
`getViewerContext()` role helper. The batch's exit gate is T0034: the Elevation Kit
primitives built once as shared components with Storybook stories (T0002), so no screen
batch ever rebuilds its own Button. **T0034 done 2026-08-08** — see
`docs/tasks/finished/T0034-elevation-kit-primitives.md`. A second task was independently
created at the same number with near-identical scope; renumbered to T0036 and trimmed to
the one genuinely new piece it surfaced (the onboarding handoff's selected-card
treatment) — see `docs/tasks/incoming/T0036-elevation-kit-selected-card.md`.

**Batch 1 · Login & onboarding — T0018, T0035, T0019**
Now spec'd by its own handoff (`handoff_onboarding/`, added 2026-08-08). T0018: the
step-0 split-screen auth page — **decided: this is the default sign-in layout for every
auth visit**, with Google OAuth added alongside email/password. T0035: the schema the
wizard writes to (workspace_type, profession, minimal user_profile). T0019: the steps 1–5
wizard with the hobbyist skip. Company create/join moves downstream of the wizard (the
designed flow doesn't include it) — it appears when a production-workspace user first
needs a company.

**Batch 2 · Storefront / browse — T0020–T0023**
Rework `/gear` into the Storefront: category sidebar driven by `product_category` (with
counts — don't hardcode the mockup's 11 categories; the pipeline only has cameras + lenses
today and the sidebar should tell the truth), URL-param search + pagination (server-rendered,
shareable), hero/featured rows, saved items. Ratings deferred — no data source.

**Batch 3 · Package Builder elevation — T0024–T0026**
Restyle the existing (already-wired!) builder to the Elevation spec, add the drawer catalog +
bulk actions, notes/change-log (finally lands T0008), and "Send quote" v1 — the status
transition draft → sent that creates `package_item_quote` rows. Ends with the workflow's
first half real.

**Batch 4 · Rental House Map — T0027–T0028**
Lat/lng migration + seed the 14 Ohio houses from `ohio_rental_houses.csv` (your real
regional dataset — better than fictional LA houses for demos), then the map page with the
two-way card↔pin selection and computed package-match line.

**Batch 5 · DP Profile — T0029–T0030**
The biggest schema batch: profile, owned kit, credits, rates, documents, house accounts,
crew tables — then the page, with rate visibility as a query-level role rule.

**Batch 6 · RFQ document — T0031–T0032**
The capstone: quote-document layer + `rental_house_members` + thread + COI, then the
dual-role RFQ page. Deliberately last — it depends on foundations (roles), builder
(send quote), and profile (COI docs), and it's where the planning-surface-vs-system-of-record
boundary must be held.

**Pacing rule (the "slow down" you asked for):** one task file at a time, and a task isn't
done until its *Verification* section is satisfied — the same discipline your T0003–T0005
files already model (rendered-HTML or direct-DB verification, not "it compiles"). Batches
end at a shippable state; if a batch stalls, the app still works.

---

## 6. Systems-design guardrails (future-proofing, in priority order)

1. **One data-access pattern.** Everything goes through `queries.ts` typed functions. When
   the pattern strains (per-role query variants), split by domain
   (`queries/products.ts`, `queries/quotes.ts`, …) — never bypass into raw client fetches.
2. **Authorization at the query boundary.** Role rules live where data is fetched.
   A producer's request for a DP profile never *contains* the rates.
3. **Tokens before screens.** The elevation ramp goes into `globals.css` as CSS variables
   once (T0015); five screens consume it. Never inline the hex values from the prototypes.
   Note `docs/brand.md` says "borders over shadows" — the handoff deliberately inverts this;
   update brand.md when T0015 lands rather than leaving the contradiction.
4. **Migration discipline.** One authoritative migration path (T0013 decision). Every
   new-table batch (2, 5, 6) writes a migration + mirrors `schema.ts`, in that order.
5. **Planning surface, not system of record — but the transaction host.** (Confirmed
   2026-08-08.) No asset/serial/bin tables; house-side "inventory" facts on quotes are
   *house-entered text/numbers on the quote*, not synced state we promise to keep true.
   Altoscope does NOT replace the house's rental-management system — but it DOES host the
   money between production and house (T0033), which is the business-model reason the RFQ
   document layer must be solid.
6. **Two state machines, never conflated** (straight from your workbook's schema map):
   `package_item_status` is a planning workflow; asset status is an inventory concept.
   The RFQ document gets its own third, small status set. Keep all three separate.
7. **URL as state for browse surfaces.** Search, category, page number → `searchParams`,
   server-rendered. Free back-button, shareable links, no client cache to invalidate.
8. **Optimistic UI only where it already exists.** The builder's add/remove pattern
   (temp-id swap, rollback on failure) is good; don't extend optimism to money-bearing
   actions (send quote, approve) — those want explicit pending states.

---

## 7. Open decisions (flagged, not blocking)

- **Map library** — prototype uses Leaflet; T0028 recommends MapLibre GL (free,
  vector, dark styles without CSS filter hacks) but Leaflet is fine to start. Decide at T0028.
- **Ratings** — mockup shows stars; no data source exists. Deferred entirely. Options later:
  scrape review counts, or drop ratings from cards (the spec's `showRatings` prop
  anticipates exactly this).
- **Featured/hero curation** — heuristic (newest flagship w/ image) vs a tiny
  `is_featured` flag. T0022 starts heuristic.
- ~~**Storybook (T0002)** — still open~~ **Done 2026-08-08** — see
  `docs/tasks/finished/T0002-storybook-integration.md` and T0034.
- ~~**The strategic question** from the workbook: planning surface vs system of record.~~
  **Answered 2026-08-08:** planning surface that talks to rental houses, plus hosting the
  production↔house monetary transaction (see §4 and T0033). Not the houses' rental
  management system.
- **Payments provider** — Stripe Connect is the obvious shape (platform between two
  businesses, holds/deposits, payouts) but the pick belongs to T0033's scoping, not here.
- **Rejected direction (2026-08-08 workshop): consumer rental marketplace.** A "GrubHub
  for lower-tier rental houses" idea — Altoscope hosting bookings for consumer-gear houses
  (DSLR/mirrorless, publicly-priced) with a transaction cut — was considered and
  **rejected**. It's a third, undifferentiated business (consumer marketplace + commission)
  entered against incumbents (LensRentals/ShareGrid/B&H) who already own the segment, and
  it repeats the exact failure mode this project already identified: ShareGrid/KitSplit/
  BorrowFox all attempted vertical integration into transactions without decisively
  winning, because top rental houses compete on relationships, not availability, and a
  commission model taxes an existing relationship rather than creating value. It's also
  the segment furthest from the validated ICP (mid-tier production studios, DP-as-champion)
  and furthest from the validated pain points (COI management, production verification —
  which matter in the relationship-driven B2B tier, not consumer rental). **Resolution:**
  don't gatekeep by rental-house type at signup — anyone can list in the database, good for
  coverage — but don't build the transactional/booking feature that would make a
  consumer-gear listing *useful* as a transaction. The product's own shape does the segment
  filtering; no explicit rule needed. **Do not revisit this without new evidence.**
- **Why T0033's $0-cut hosted payments do NOT repeat the rejected marketplace mistake**,
  despite surface similarity ("money moves through Altoscope"): ShareGrid et al. failed
  because they tried to *be* the marketplace — inserting themselves as the matching layer
  between supply and demand, taking a % cut, competing on availability in a
  relationship-driven industry. The $0-cut design (Stripe Connect direct charges, $0
  application fee, Altoscope never custodies funds — see
  `post-mvp-on-platform-payments.md`) doesn't match anyone with anyone (the relationship
  already exists via RFQ/workflow), doesn't take a cut, and isn't competing to create the
  relationship — it's a payment rail *attached to* a relationship the workflow tools
  already built. The failure mode is specifically "taking a cut as an intermediary," not
  "hosting payments at all." Planned as a paid-tier feature initially (evidence of
  workflow stickiness), with the explicit possibility of dropping it to free tier later —
  not a revenue line to protect long-term.
- **Billing model (decided 2026-08-08, T0038):** studio tier flat/unlimited once paid, no
  per-seat/per-production metering. Free/hobby tier gets a *lifetime* cap (not monthly,
  Figma page-cap pattern) shared across package builder + RFQ as one funnel. Browse/
  database stays uncapped for everyone always — top-of-funnel, not the paywalled
  workflow. Exact cap number and unit (productions vs. RFQs/quote-requests sent) still
  undecided — see T0038.
- **Company model (decided 2026-08-08, T0037):** solo users need no company at all
  (`productions.companyId` going nullable); studio creation is atomic
  (`companies` + owner `companyMembers` row, one transaction, never a two-step gap); a
  user's prior solo productions never auto-migrate into a company they create later.
- **Role taxonomy (T0039) and approval authority (T0040)** — both explicitly undecided as
  of 2026-08-08, blocked pending a decision from Darin. Don't default into an
  implementation choice on either while building adjacent tasks (T0006, T0017, T0026).
