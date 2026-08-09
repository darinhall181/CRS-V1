---
title: Build package_item_comment table + Notes panel persistence
status: done
severity: medium
type: task
component: www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-05
completed_date: 2026-08-08
verified_live: true
github_issue: null
---

## Summary
**Done 2026-08-08:** Built `package_comments` + `package_comment_mentions` (see decision
below on scoping/naming), wired the Notes panel to real create/read, and verified live —
posted a comment with a real @mention and confirmed via direct DB read-back that the
mention landed as a join-table row (`mentioned_user_id` → a real `users.id`), not a
substring in the body.

The Notes panel in Package Builder's right rail has nothing to read/write
to — no comment table exists in `schema.ts`. Flagged as a demo-blocking gap
in the original design handoff.

## Notes (2026-08-08)
Reconfirmed while rebuilding the panel's styling — it's still a static "Reply or
@mention…" composer with a "No comments yet" placeholder, no backend. Explicit ask from
Darin: when this gets built, the whole thing needs to be real user-created content, not
just a message string —
- Comments belong to a real user (author, not a free-text name) via the existing
  `users`/session identity, timestamped for real.
- `@mention` needs to actually resolve to a real user (likely someone with a
  `productionMembers`/`companyMembers` row on this production), not just accept
  arbitrary `@text`.
- Whatever table lands (`package_item_comment` per the title, or scoped to the whole
  package rather than one line item — worth deciding which before building) should
  support that mention as a real reference, not a substring in the body, so a
  mentioned user could eventually be notified (see T0046 — Notification Center).

## Follow-up (2026-08-08) — mention UX polish
Same day, after the initial build: Darin asked for the `@mention` to behave as a real
atomic "block" (pill, deletable as one unit) rather than plain inserted text, plus a
live typeahead when typing `@` inline. Both added to the composer without a
contenteditable/rich-text editor — kept the risk down since he wanted to ship fast:
- Composer draft is now a segment list (text runs + mention chips), not a flat string.
  A mention is its own segment; Backspace on an empty trailing text field or the pill's
  × removes the whole chip in one action — no partial-edit state possible.
- Typing `@` (start of string or after a space) opens a dropdown filtered against real
  `mentionableUsers` (prefix matches sort first), navigable with ↑/↓, Enter/Tab/click to
  pick — same real-reference validation as before, just faster to invoke.
- Posted comments render `@Name` as the same pill, split on that comment's actual
  `mentionedUserIds` (not any string that happens to match a name).

All in `package-builder-client.tsx`'s `NotesPanel`/`MentionPill`/`renderCommentBody`.
Verified live: typeahead filter, Enter-to-pick, continued typing, post, and pill
rendering all confirmed end-to-end.
