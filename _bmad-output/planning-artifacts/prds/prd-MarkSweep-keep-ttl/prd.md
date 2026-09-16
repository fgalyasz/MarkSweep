---
title: MarkSweep keep TTL
status: final
created: 2026-09-16
updated: 2026-09-16
parent_issue: 57
---

# PRD: MarkSweep keep TTL

Hobby/solo. One user-visible goal: a keep rule can hold matching mail (e.g. a sender) for N days, then Scan moves those messages to Trash without a Sweep click.

## 1. Vision

Forever-keep is wrong for receipts and newsletters he still wants for a week. A Days field on the rule protects while the message date is inside the window. Older matching mail is auto-trashed on Scan (TRASH only). Empty days means forever.

## 2. User journeys

- **UJ-1. Sheet.** From + Exact + `shop@x.com` + `7`. Mail from that sender newer than 7 days is protected.
- **UJ-2. Scan.** Same sender, 8 days old: moved to Gmail Trash. Status names how many expired keeps were auto-trashed.
- **UJ-3. Context menu.** Keep → From → 7 days upserts that identity (does not duplicate).

## 3. Features

#### FR-1: Optional keepDays

`keepDays` nil or ≤0 is forever. Positive days compare `now - message.date` to `days * 86400`.

**Consequences:**
- Legacy JSON without `keepDays` loads as forever.
- Duplicate identity is still field+match+value; upsert updates days.

#### FR-2: Protect vs expire

In-window match → protected Keep. Expired match → `isKeepExpired`, selected, not protected.

**Consequences:**
- A forever rule still wins if it is the first match; one identity per field+match+value.

#### FR-3: Auto-trash on Scan

After classify+keep apply, expired ids are `batchModify` TRASH. Confirm Sweep is not used for this path.

**Consequences:**
- App must be scanned (not a background daemon).
- Failures stay in the list selected.

## 4. Non-goals

- Permanent DELETE.
- Timer while the app is quit (next Scan catches up).
- Per-message override of the rule window.

## 5. Success metrics

- **SM-1**: 7-day From rule keeps yesterday’s mail and auto-trashes 8-day-old mail on Scan.
- **SM-C1**: Expiry math, upsert days, legacy decode; `swift test` green.
