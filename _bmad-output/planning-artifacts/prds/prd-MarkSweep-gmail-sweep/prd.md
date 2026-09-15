---
title: MarkSweep Gmail sweep
status: final
created: 2026-09-15
updated: 2026-09-15
parent_issue: https://github.com/fgalyasz/MarkSweep/issues/6
---

# PRD: MarkSweep Gmail sweep

Hobby/solo. One user-visible goal: scan a connected Gmail, review AI-marked messages, and move the selection to Trash in one confirmed action, with a storage estimate.

## 1. Vision

Gmail’s Spam folder is not enough. MarkSweep finds promotions, newsletters, large mail, phishing, and harassment still sitting in the mailbox, marks them, and waits. The user sweeps. Mail goes to Trash, not permanent delete.

## 2. User journeys

- **UJ-1. Scan.** Connected Anna hits Scan. Progress runs. A list appears with subject, sender, date, size, reason, and a checkbox. Suspect, spam-like, and large rows start checked. Personal-looking mail starts unchecked.
- **UJ-2. Review.** She filters Suspect, Large, Spam folder, or All. She opens a row and reads a plain-text preview (no HTML engine). She unchecks a false positive.
- **UJ-3. Sweep.** She confirms. Selected messages gain the TRASH label. A summary shows count and estimated bytes. Failures stay listed; the rest succeed.
- **UJ-4. Safety.** There is no timer and no sweep on scan complete. Closing the app leaves mail untouched.

## 3. Features

#### FR-1: Scan queries

Scan unions capped Gmail queries: spam, promotions, social, larger-than-threshold, and recent inbox. Duplicate IDs collapse. Default per-query cap is 500. Default large threshold is 5 MB.

**Consequences:**
- A 6 MB inbox PDF is in the list as large even if it looks personal.
- Mail older than the inbox window is still found if it matches spam/promotions/social/larger queries.

#### FR-2: On-device classifier

Heuristics run on labels, `List-Unsubscribe`, size, subject, snippet, and optional body. Verdicts: `keep`, `suspect`, `spamLike`, `large`. Weak signals stay `keep`. Bodies never leave the device.

**Consequences:**
- `SPAM` / `CATEGORY_PROMOTIONS` / `CATEGORY_SOCIAL` → `spamLike`.
- Phrase hits for harassment or phishing → `suspect`.
- Size ≥ threshold → `large` unless a stronger junk label already applied.
- Inbox `keep` may fetch full body once and re-classify; still on-device.

#### FR-3: Review queue

Default selection follows verdict (junk/large on, keep off). Filters: all, suspect, large, spam folder. Toggle one row or the visible set.

**Consequences:**
- Changing filter does not clear selections on hidden rows.
- Sweep plan uses selected rows across filters.

#### FR-4: Plain preview

Preview is stripped text, scripts and tags removed, length capped. No `WKWebView` for message HTML.

**Consequences:**
- A `<script>` in a body does not run.
- Empty body falls back to snippet.

#### FR-5: Trash sweep

Sweep calls Gmail `batchModify` adding `TRASH`, chunks of at most 1000 IDs. No `DELETE`. Confirm UI shows count and `formatBytes` of the selection.

**Consequences:**
- User can recover from Gmail Trash for ~30 days.
- HTTP failure on one chunk reports remaining IDs; other chunks may still succeed.

#### FR-6: Quota-friendly fetch

List IDs first. Metadata for classify. Full payload only when the first verdict is `keep` and the message is in INBOX.

**Consequences:**
- Promotions do not download bodies.
- Harassment in a recent inbox mail can still be marked after the full fetch.

## 4. Non-goals

- Permanent Gmail delete.
- Scheduled sweep.
- Cloud LLM.
- Scanning the entire mailbox without caps.
- Calendar, Drive, or non-Gmail mail.

## 5. Success metrics

- **SM-1**: After a scan, Anna can uncheck two false positives and sweep the rest to Trash; those threads appear in Gmail Trash.
- **SM-C1**: Core tests cover query lists, classify matrix (pos/neg), filters, default selection, preview stripping, ID chunking, sweep plan bytes, and refine-on-inbox-keep.
