---
title: MarkSweep keep rule edit
status: final
created: 2026-09-16
updated: 2026-09-16
parent_issue: 49
---

# PRD: MarkSweep keep rule edit

Hobby/solo. One user-visible goal: delete a keep rule with a button, add one from a message context menu, and never store duplicates.

## 1. Vision

The keep-rules sheet has no usable delete on macOS. Adding a From rule means typing the address. Right-click on a row should offer From / To / Subject (and the other fields) with the message’s value. The same field+match+value pair exists at most once.

## 2. User journeys

- **UJ-1. Delete.** Trash control on the row removes that rule. Protected mail that only matched it returns to the classifier verdict.
- **UJ-2. Context menu.** Right-click a message → Keep → From: `a@b.com`. Address fields use Exact + extracted email; Body uses Contains. Empty fields are omitted.
- **UJ-3. Duplicate.** Add or edit that would match an existing identity is ignored. Context menu disables that item.

## 3. Features

#### FR-1: Visible delete

Each rule has a Delete control. `removeKeepRule(id:)` persists and re-applies.

**Consequences:**
- Swipe-only delete is not enough on macOS.

#### FR-2: Context-menu add

Suggestions come from `matchFields`. Adding inserts unless duplicate.

**Consequences:**
- Default match: Exact for From/To/Cc/Recipient/Subject; Contains for Body.

#### FR-3: Unique rules

Identity is field + match + normalized value. Insert/update/load drop duplicates (first wins).

**Consequences:**
- Two blank Add rules with the same defaults: the second is a no-op.

## 4. Non-goals

- Regex, AND groups, or editing from the context menu.
- Undo stack.

## 5. Success metrics

- **SM-1**: Trash removes the row; right-click From adds Exact sender email.
- **SM-C1**: Duplicate insert/update, unique load, suggestions; `swift test` green.
