---
title: MarkSweep stats fit
status: final
created: 2026-09-16
updated: 2026-09-16
parent_issue: 28
---

# PRD: MarkSweep stats fit

Hobby/solo. One user-visible goal: mailbox numbers stay fully visible at the default Review window size.

## 1. Vision

The header design is right. At the saved/default split, four equal columns shrink and ellipsize `9…`, `15,56…`, `0…`. Metrics must keep their digits; the grid may wrap to two rows.

## 2. User journeys

- **UJ-1. Default window.** Mailbox count, used storage, free space, and cleaned totals are complete (no `…` on numbers).
- **UJ-2. Narrow middle column.** Metrics wrap to two rows instead of truncating.
- **UJ-3. Wide window.** Four metrics stay on one row.

## 3. Features

#### FR-1: No ellipsis on stats digits

Titles do not hyphenate. Values are not `lineLimit(1)`-squeezed. Storage headline is used bytes only; plan and free sit on the caption.

**Consequences:**
- `storageHeadline` has no `/`.
- Truncation of counts/bytes in the header is a bug.

#### FR-2: Adaptive header + column widths

Adaptive grid (min cell ~168 pt). Content column is the flexible one; preview has a max width. Window default is wide enough for one row.

**Consequences:**
- A previously saved small frame still shows full numbers (two rows).
- Empty preview no longer steals half the window.

## 4. Non-goals

- Changing which stats are shown.
- Redesigning filters or Sweep.

## 5. Success metrics

- **SM-1**: Screenshot-sized window shows full mailbox and storage figures.
- **SM-C1**: Headline vs pair/detail lines; `swift test` green.
