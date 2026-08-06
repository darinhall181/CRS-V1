---
name: file-issue
description: Files a GitHub issue in darinhall/Altoscope for a bug or problem found during development — especially UI/browser-session work. Use when the user reports something broken, wrong, or worth tracking and wants it filed as a real GitHub issue rather than just a local task.
---

# File Issue

Turns a described problem into a well-formed GitHub issue in `darinhall/Altoscope`, so bugs found during active development — especially visual/browser-driven UI work in an interactive session — don't get lost between sessions or forgotten by the time someone circles back.

## When to use

- The user describes a bug, visual glitch, or broken behavior and asks for it to be filed/logged/tracked as an issue
- Especially useful mid-session while driving the app in a browser — capture it immediately rather than relying on memory later
- Not for speculative "might be worth checking" items — this is for confirmed or clearly-described problems

## Steps

1. **Gather what's already known** from the conversation before asking the user anything: what's broken, where (file/page/component), how to reproduce it, any screenshot or error message already shared, and whether it relates to an existing tracked task. Don't make the user repeat information already in context.

2. **Check for duplicates first**:
   ```bash
   gh issue list --repo darinhall/Altoscope --search "<key terms>" --state open
   ```
   If a clear duplicate exists, comment on it instead of filing a new one:
   ```bash
   gh issue comment <number> --repo darinhall/Altoscope --body "<what you observed, any new detail>"
   ```
   and say so rather than creating a near-duplicate.

3. **File the issue** (labels are `bug`, `documentation`, `duplicate`, `enhancement`, `good first issue`, `help wanted`, `invalid`, `question`, `wontfix` — use `bug` for defects, `enhancement` for feature/polish requests, and don't invent labels that aren't in this list):
   ```bash
   gh issue create --repo darinhall/Altoscope \
     --title "<concise, specific title — not 'bug in package builder'>" \
     --body "<body, see template below>" \
     --label bug
   ```

   Body template — omit any section you don't have real information for, rather than filling it with a placeholder:
   ```markdown
   ## What's happening
   <description of the actual observed behavior>

   ## Where
   <file/page/component, e.g. `www/src/app/(app)/package-builder/package-builder-client.tsx` — catalog drawer>

   ## Steps to reproduce
   <if known>

   ## Notes
   <anything else relevant — e.g. "unconfirmed after dev server restart", "only seen via the browser-extension session">
   ```

4. **Report back** the issue URL. If a related task is already open in the local task list (TaskCreate/TaskUpdate), say so and suggest it should reference the issue number — don't silently edit tasks without being asked.

## What NOT to do

- Don't file speculative issues for things that are only "maybe" a problem
- Don't guess at repro steps, affected files, or root cause you're not confident about — leave those sections out rather than inventing content
- Don't create labels that don't exist in the repo without asking first
- Don't skip the duplicate check — repeated visual bugs found across multiple browser sessions are exactly the case this exists to prevent from becoming issue spam
