---
title: Package Builder still has UI-only "live" data — saved time, status, vendor link
status: open
severity: medium
type: task
component: www/src/app/(workspace)/package-builder/, www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Flagged by Darin while reviewing the rebuilt Package Builder page: several pieces of the
UI read as live/dynamic but aren't actually backed by a real update path yet. Three
separate gaps, worth splitting when this gets picked up rather than solving as one task:

1. **"Saved just now."** Static text next to the page title — there's no real
   `updatedAt` write path behind it. Every package/package-item mutation (add, remove,
   qty change once that exists) needs to actually stamp a real timestamp, and the label
   needs to read that timestamp (e.g. "Saved 2m ago") instead of a hardcoded string.
   This isn't a cron-job problem — it's a missing write-then-read: no polling job is
   needed if the timestamp updates on every real mutation and the label just formats
   elapsed time client-side.
2. **Package-level status pill** (Draft / Sent / In Progress, next to the title).
   Currently derived client-side from the real per-line-item statuses (see
   `derivePackageStatus` in `package-builder-client.tsx`) — reasonable as a rollup, but
   worth checking whether `packages` should eventually carry its own real status field
   once there's an actual send/accept workflow (T0031/T0032's RFQ batch), rather than
   staying purely inferred forever.
3. **Footer's rental-house line** ("{shootDays} shoot days · {VENDOR_NAME}"). `VENDOR_NAME`
   is currently a hardcoded `"DaVinci Rentals"` constant — real for *this* seeded
   production/vendor pairing, but there's no real productionrental-house relationship
   backing it (no join, just a constant). Once a production can actually be linked to a
   rental house it's quoting (T0031 territory again), this should read from that real
   relationship instead of the constant.

## Notes
None of these are wrong today (the seeded data happens to make the constant/derived
values correct) — they're just not wired to update if the underlying reality changes.
Don't build speculative infrastructure (no cron needed) — just make sure each of these
reads from a real write path once one exists.
