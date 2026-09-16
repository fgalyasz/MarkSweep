---
title: MarkSweep Google Photos Picker
status: planned
created: 2026-09-16
updated: 2026-09-16
parent_issue: 44
---

# PRD: MarkSweep Google Photos Picker

Hobby/solo. One user-visible goal: analyze a Picker-selected Google Photos set for likely duplicates and better shots, then hand Ferenc a list — not an API bulk delete.

## 1. Vision

After 2025-03-31 the Google Photos Library API cannot enumerate or delete the existing library. The Picker can grant read access to photos the user chooses. MarkSweep must not promise Google Photos mass delete.

## 2. User journeys

- **UJ-1. Connect.** Account picker: Google Photos. Coming-soon is replaced by Picker connect.
- **UJ-2. Pick.** Google Picker UI; he selects an album or batch. MarkSweep reads those assets only.
- **UJ-3. Review.** Duplicate groups and quality rank. Actions: open in Google Photos / copy a checklist. No Sweep-to-delete against Google.

## 3. Features

#### FR-1: Picker session

OAuth + Picker for a user-selected set. Tokens in Keychain, separate from Gmail if scopes differ.

**Consequences:**
- `.googlePhotos` becomes enabled for Picker, not for library delete.
- Copy still states the official API cannot delete the library.

#### FR-2: Dedupe on the picked set

Same PhotoSource list/thumbnail path as iCloud where possible. Rank better shots on-device.

**Consequences:**
- `delete` on the Google adapter throws `notAvailable` (or opens Photos).
- No undocumented scraping.

#### FR-3: Honest empty delete

UI never shows Sweep to Trash for Google Photos. It shows Open / Copy IDs.

**Consequences:**
- Shared review chrome may hide the Sweep bar for this account kind.

## 4. Non-goals

- Bulk delete of the Google Photos library.
- iCloud in this PRD.
- Unofficial Google endpoints.

## 5. Success metrics

- **SM-1**: A picked set shows duplicate groups; delete is not offered.
- **SM-C1**: Adapter delete throws; Picker mapping unit-tested.
