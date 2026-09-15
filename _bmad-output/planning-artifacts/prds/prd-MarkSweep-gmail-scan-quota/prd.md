---
title: MarkSweep Gmail scan quota
status: final
created: 2026-09-15
updated: 2026-09-15
parent_issue: https://github.com/fgalyasz/MarkSweep/issues/17
---

# PRD: MarkSweep Gmail scan quota

Hobby/solo. One user-visible goal: Scan returns a review list instead of dying on Gmail per-minute quota.

## 1. Vision

A new Cloud project plus five list queries and a metadata GET per id burns the per-user Gmail unit budget in seconds. MarkSweep must pace requests, keep a small default cap, and keep what it already fetched.

## 2. User journeys

- **UJ-1.** Connected Ferenc hits Scan. After a short wait he has a list, even if Gmail later says slow down.
- **UJ-2.** Quota mid-scan. Status explains wait-and-scan-again. Existing rows stay.

## 3. Features

#### FR-1: Smaller default cap

Default `perQueryCap` is 40. A saved `500` (old default) migrates to 40.

**Consequences:**
- First scan lists at most 40 hits per query.
- Custom caps at or below 80 stay.

#### FR-2: Pace and retry

Scans pause between Gmail calls. 403/429 with quota/rate-limit text retry with backoff, then stop early.

**Consequences:**
- Tests inject a sleeper; no real waits.
- Remaining ids are skipped; fetched items are kept.

#### FR-3: Status copy

Quota stop is not a hard Connect error. Status says scanned N, then slow down.

**Consequences:**
- The review list is usable.
- Sweep still only selected rows.

## 4. Non-goals

- Google quota increase request from the app.
- Scanning the whole mailbox in one click.

## 5. Success metrics

- **SM-C1**: Tests cover migrate 500→40, retry then success, stop-early outcome; `swift test` green.
