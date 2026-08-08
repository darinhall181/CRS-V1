---
title: Quote document layer — RFQ table, rental_house_members, line revisions, thread, COI
status: open
severity: high
type: task
component: www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 6 (RFQ), 1 of 2. `package_item_quote` is item-scoped; the RFQ screen is a *document*
two parties revise and discuss. Missing layer:

```
rental_house_members(id, rental_house_id, user_id, role enum(agent, manager),
                     unique(rental_house_id, user_id))   -- the missing 4th role system
rfq(id, package_id → packages, rental_house_id, location_id nullable,
    status enum(open, quoted, revised, approved, expired, declined),
    version int, hold_expires_at timestamptz nullable,
    discount numeric, damage_waiver_pct, delivery_fee, delivery_note,
    created_by, created_at, updated_at)
rfq_line(id, rfq_id, package_item_id → package_items,
         qty, day_rate, line_status enum(pending, confirmed, substitution, house_added,
         unavailable), substituted_product_id nullable, sub_rental_source text nullable,
         sub_rental_cost numeric nullable, client_note, internal_note, sort_order)
rfq_message(id, rfq_id, author_id → users, body, created_at)   -- activity thread
production_coi(id, production_id, insured_name, carrier, policy_number, file_url,
               gl_amount, equipment_amount, workers_comp_amount, expires_on,
               verified_at nullable, verified_by nullable)
```

Design rules (from the workbook's schema-map findings + the handoff):
- **Three separate state machines**: package_item_status (planning) / rfq.status
  (document) / rfq_line.line_status (per-line negotiation). Never conflate.
- `client_note` vs `internal_note` on lines is the production-view/house-view split —
  visibility is a query rule, same principle as T0030 rates.
- House "inventory" facts ("2 in yard") are house-*entered* text on the line, not synced
  state — the planning-surface boundary (plan doc guardrail #5). Margin panel derives from
  day_rate/sub_rental_cost per line; list value from `rental_house_inventory` reference
  rates.
- Timeline events: extend T0025's `package_event` with a nullable `rfq_id` rather than a
  new table (decision deferred there, made here).
- T0026's send-quote gets upgraded to create an `rfq` + lines; `package_item_quote`
  becomes the per-item rollup it was designed to be (selected-quote mirror into
  `day_rate_snapshot` unchanged).
- **Payments are coming (T0033, scope decided 2026-08-08):** the approved RFQ is the
  anchor a transaction attaches to. Therefore approval must write immutable snapshot
  totals onto the `rfq` row (subtotal, discount, waiver, delivery, grand total) rather
  than deriving them live — a payment can never reference a moving number.

## Verification
Seed one full RFQ mirroring the mockup's Keslow scenario (substitution, house-added line,
hold expiry); joined read-backs for both view shapes return the right columns.
