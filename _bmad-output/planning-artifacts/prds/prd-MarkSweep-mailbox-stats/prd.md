---
title: MarkSweep mailbox stats
status: final
created: 2026-09-16
updated: 2026-09-16
parent_issue: 20
---

# PRD: MarkSweep mailbox stats

Hobby/solo. One user-visible goal: after Connect, the sidebar shows mailbox message count, Google storage used vs plan, and how much MarkSweep has moved to Trash.

## 1. Vision

Scan is a sample. Ferenc still needs the whole mailbox size, what this session cleaned, and how much of the Google One / free 15 GB plan is left.

Gmail has no API for “bytes in Gmail only”. Message count comes from Gmail profile. Used/limit/free come from Drive `about.storageQuota` (the same pool as Gmail + Drive + Photos). Cleaned figures are MarkSweep’s own Trash moves.

## 2. User journeys

- **UJ-1. Connected.** Sidebar: N messages; X of Y used, Z free; cleaned this session 0.
- **UJ-2. After Sweep.** Session and lifetime cleaned counts/bytes go up. Quota refreshes. Copy says Trash still counts until Gmail Trash is emptied.
- **UJ-3. Reconnect.** New Drive metadata scope is requested. Lifetime cleaned survives disconnect.

## 3. Features

#### FR-1: Mailbox count

`users.getProfile.messagesTotal` is the mailbox size in messages.

**Consequences:**
- Shown after Connect, Scan, and Sweep.
- Missing total displays 0 only if Google omits the field.

#### FR-2: Account storage vs plan

Drive `about.get` `storageQuota.usage` / `limit`. Remaining is `max(0, limit - usage)`. Missing limit (unlimited) shows used only.

**Consequences:**
- Needs `drive.metadata.readonly` and Drive API enabled.
- Quota fetch failure does not disconnect; it shows storage unavailable.
- Copy states the quota is shared with Drive and Photos.

#### FR-3: Cleaned totals

Session totals reset on quit/disconnect. Lifetime totals persist in settings. Bytes use `sizeEstimate` of successfully trashed ids.

**Consequences:**
- Failed trash chunks are not counted.
- Lifetime is not reset on Disconnect.

#### FR-4: Visible vs selected

The list shows `Showing A of B`. Sweep still uses selected rows across filters.

**Consequences:**
- Suspect filter with 1 row and 167 selected no longer looks like a one-message mailbox.

## 4. Non-goals

- Exact Gmail-only bytes (Google does not expose it).
- Emptying Gmail Trash from MarkSweep.
- Google One plan name.

## 5. Success metrics

- **SM-1**: After reconnect, Ferenc sees message count and used/free vs limit.
- **SM-C1**: Parse profile/quota, remaining, sweep byte sum, settings decode without swept keys; `swift test` green.
