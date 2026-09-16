---
title: MarkSweep iCloud Photos
status: planned
created: 2026-09-16
updated: 2026-09-16
parent_issue: 39
---

# PRD: MarkSweep iCloud Photos

Hobby/solo. One user-visible goal: on a user-marked iCloud Photos set, find likely duplicates, keep the better shot, and delete the rest only after review.

## 1. Vision

The original product is one Mac app, several clouds. Gmail shipped. iCloud uses PhotoKit (`PHPhotoLibrary`), not iCloud REST. Scope is only photos Ferenc marks (album, favorites, or an in-app pick) — never the whole library unattended.

## 2. User journeys

- **UJ-1. Enable.** Account picker: iCloud Photos. First use asks Photos permission. Denied stays disconnected.
- **UJ-2. Mark a set.** He picks an album or tagged set. Scan ranks near-duplicates and quality.
- **UJ-3. Review and sweep.** Same mark-and-sweep chrome as Gmail. Confirm deletes via PhotoKit. Keep rules style allowlist can wait.

## 3. Features

#### FR-1: PhotoSource PhotoKit adapter

`PhotoSource` lists, thumbnails, and deletes for the marked set. No TCC.db writes. System Photos prompt only.

**Consequences:**
- Coming-soon alert goes away for iCloud when this ships.
- Account kind `.iCloudPhotos` becomes enabled.

#### FR-2: Dedupe on marked set

Near-duplicate groups plus a better-shot rank (resolution, sharpness proxy). User confirms which copies go.

**Consequences:**
- Whole-library crawl is out of scope.
- On-device only; no photo bytes to a third-party API.

#### FR-3: Review then delete

No auto-delete. Sweep uses PhotoKit delete on selected assets.

**Consequences:**
- Recently Deleted is Apple’s recovery path, not MarkSweep Trash.

## 4. Non-goals

- Google Photos in this PRD.
- Hidden/unmarked library sweep.
- iCloud REST or undocumented APIs.

## 5. Success metrics

- **SM-1**: A marked album of duplicates can be reviewed and reduced without touching other albums.
- **SM-C1**: PhotoSource adapter tests with fakes; no live PhotoKit in unit tests.
