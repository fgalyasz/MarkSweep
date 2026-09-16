---
title: MarkSweep empty Gmail Trash
status: planned
created: 2026-09-16
updated: 2026-09-16
parent_issue: 35
---

# PRD: MarkSweep empty Gmail Trash

Hobby/solo. One user-visible goal: after Sweep, Ferenc can empty Gmail Trash from MarkSweep so Google storage actually drops.

## 1. Vision

Mailbox stats show used vs plan. Sweep only adds `TRASH`. Google still counts those bytes until Trash is emptied. The header already warns; this increment does the empty, with an explicit confirm.

## 2. User journeys

- **UJ-1. After Sweep.** A control offers Empty Trash. Confirm names that it is permanent after ~30 days is already gone — emptying Trash deletes now.
- **UJ-2. Quota.** After success, storage snapshot refreshes; used bytes fall if Trash held the swept mail.
- **UJ-3. Cancel.** Dismiss leaves Trash intact.

## 3. Features

#### FR-1: Confirm empty

Empty Trash is never automatic. Confirm copy states messages are removed from Trash and storage should free.

**Consequences:**
- Keep rules do not apply to messages already in Trash.
- Sweep still only `TRASH`.

#### FR-2: Gmail empty

Use the Gmail API to empty the user Trash (not per-id DELETE during Sweep).

**Consequences:**
- Failures surface in the status bar; partial empty is reported.
- Quota snapshot reloads on success.

## 4. Non-goals

- Permanent DELETE from the review list.
- Auto-empty on a timer.

## 5. Success metrics

- **SM-1**: After Empty Trash, Drive `storageQuota.usage` is lower when Trash held mail.
- **SM-C1**: Confirm path has tests for “no empty without confirm”; `swift test` green when implemented.
