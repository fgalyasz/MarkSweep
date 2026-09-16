---
title: MarkSweep scan coverage
status: final
created: 2026-09-16
updated: 2026-09-16
parent_issue: 66
---

# PRD: MarkSweep scan coverage

Hobby/solo. One user-visible goal: Scan reviews more than last-year inbox × 40, shows scanned vs mailbox total, and Scan again walks older cleanable mail.

## 1. Vision

Mailbox count is the whole Gmail. Scan was five capped queries, inbox only `newer_than:365d`. That is not “all mail.” Cover spam, categories, large, all-age inbox, plus a catch-all that skips Sent/Drafts/Trash/Chats. Gmail quota still batches; Scan again continues.

## 2. User journeys

- **UJ-1.** After Scan, Mailbox shows `Scanned A of B` (B = profile `messagesTotal`).
- **UJ-2.** Status says to Scan again for older mail while a catch-all page remains.
- **UJ-3.** Second Scan keeps existing rows and appends new ids (no refetch).

## 3. Features

#### FR-1: Wider queries

Priority: spam, promotions, social, updates, forums, larger-than-threshold, inbox (no date). Catch-all: `-in:sent -in:drafts -in:trash -in:chats`. Per-query cap stays 40.

**Consequences:**
- Old inbox mail can appear.
- Sent/Drafts/Trash/Chats stay out.

#### FR-2: Continue older mail

Catch-all `nextPageToken` lives on the session. Empty list resets it. Known ids are not fetched again. Rows merge.

**Consequences:**
- Disconnect clears the cursor.
- Quota stop still keeps fetched rows.

#### FR-3: Honest counts

Mailbox detail is scanned vs `messagesTotal`. Status names reviewed/mailbox and Scan-again or caught-up.

**Consequences:**
- “Showing A of B” is not used as if B were the mailbox.

## 4. Non-goals

- One click fetching the entire mailbox past Gmail quota.
- Scanning Sent, Drafts, Trash, or Chat.

## 5. Success metrics

- **SM-1**: First scan can include inbox older than a year; second scan adds more rows.
- **SM-C1**: Query list, merge/unseen, coverage status; `swift test` green.
