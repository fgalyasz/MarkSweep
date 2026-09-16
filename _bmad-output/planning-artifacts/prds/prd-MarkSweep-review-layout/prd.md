---
title: MarkSweep review layout
status: final
created: 2026-09-16
updated: 2026-09-16
parent_issue: 24
---

# PRD: MarkSweep review layout

Hobby/solo. One user-visible goal: Review looks like Mail, not a stack of wrapping sentences in a 180 px sidebar.

## 1. Vision

Mailbox count, Google storage, and cleaned totals stay visible. They move out of the filter column into a compact header. The sidebar is account plus filters with counts.

## 2. User journeys

- **UJ-1. Connected.** Header: mailbox N, used / plan / free, cleaned 0. Sidebar: email and filters.
- **UJ-2. After Scan.** Each filter shows how many rows match. The list caption is Showing A of B.
- **UJ-3. After Sweep.** Header cleaned figures update. Filters stay selected; the list is not buried under stats copy.

## 3. Features

#### FR-1: Stats header

Mailbox, storage (used / limit / free + fill), this session, and all-time cleaned sit above the message list.

**Consequences:**
- Sidebar no longer lists those sentences.
- Shared-pool / Trash note is a storage tooltip, not a paragraph.

#### FR-2: Filter sidebar

Account (email + Disconnect) then a selectable filter list. Each row shows `matchingCount`.

**Consequences:**
- Filter is List selection, not a stack of text buttons.
- Sidebar min width is enough for an email address.

#### FR-3: Showing A of B

Caption stays on the message column, not in the filter list.

**Consequences:**
- A tight filter cannot look like the whole mailbox.

## 4. Non-goals

- New metrics or APIs.
- Emptying Gmail Trash.
- Redesigning Connect.

## 5. Success metrics

- **SM-1**: Stats are readable without wrapping in the sidebar.
- **SM-C1**: `quotaFillRatio`, `matchingCount`, storage pair/free lines; `swift test` green.
