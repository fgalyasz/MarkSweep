---
title: MarkSweep keep rules
status: final
created: 2026-09-16
updated: 2026-09-16
parent_issue: 31
---

# PRD: MarkSweep keep rules

Hobby/solo. One user-visible goal: field/value keep rules (exact or contains) never send matching mail to Trash, and Ferenc can edit them in the app.

## 1. Vision

Scan will mark spam-like mail from people he must keep, e.g. `From` = `galyasz3@gmail.com`. Rules persist in settings. A match forces Keep, unchecks the row, and blocks Sweep.

## 2. User journeys

- **UJ-1. Add rule.** Keep rules sheet: field, match (Contains / Exact), value. Save. Next Scan (and the current list) honor it.
- **UJ-2. From address.** Exact `galyasz3@gmail.com` matches `Name <galyasz3@gmail.com>` and is case-insensitive.
- **UJ-3. Contains.** Subject contains `invoice` keeps those threads even if large/spam-like.
- **UJ-4. Sweep.** Protected rows cannot be selected or swept. Removing a rule restores the classifier verdict.

## 3. Features

#### FR-1: Fields and match

Fields: From, To, Cc, Recipient (To or Cc), Subject, Body (snippet + body). Match: Contains or Exact. Empty value never matches. Address exact also matches extracted emails.

**Consequences:**
- Metadata fetch includes To and Cc.
- Matching is trimmed and case-insensitive.

#### FR-2: Never sweep

A matching rule sets Keep, `isProtected`, selected false. Toggle / Select visible / sweep plan skip protected ids.

**Consequences:**
- Heuristic spam cannot override a rule.
- Base verdict is stored so deleting a rule restores it without a new Scan.

#### FR-3: In-app editor

Sidebar opens a sheet to add, edit, and delete rules. Changes persist in `settings.json` and re-apply to the current review list.

**Consequences:**
- Disconnect does not clear rules.
- Legacy settings without `keepRules` load as `[]`.

## 4. Non-goals

- Regex, AND/OR groups, or deny-lists (always-sweep).
- Server-side Gmail filters.
- Per-account rule files.

## 5. Success metrics

- **SM-1**: Rule From exact `galyasz3@gmail.com` keeps that sender out of Sweep.
- **SM-C1**: Match/no-match, email extract, settings round-trip, protect/restore; `swift test` green.
