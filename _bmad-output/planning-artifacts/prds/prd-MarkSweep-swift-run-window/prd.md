---
title: MarkSweep swift run window
status: final
created: 2026-09-15
updated: 2026-09-15
parent_issue: https://github.com/fgalyasz/MarkSweep/issues/11
---

# PRD: MarkSweep swift run window

Hobby/solo. One user-visible goal: `swift run MarkSweep` shows a MarkSweep window in front.

## 1. Vision

An unbundled SwiftPM executable is a command-line process. macOS does not treat it as a regular app, so SwiftUI's WindowGroup can exist while nothing appears. Development must still show the UI.

## 2. User journeys

- **UJ-1.** Ferenc runs `swift run MarkSweep` from Terminal. A MarkSweep window comes to the front with the account picker. The process stays up until he quits the app or sends Ctrl+C.

## 3. Features

#### FR-1: Regular activation

On launch, MarkSweep sets `NSApplication` activation policy to `.regular` and activates, then orders its windows front.

**Consequences:**
- `swift run` shows a Dock icon and a key window.
- Closing the window can hide it; Quit or Ctrl+C ends the process.

## 4. Non-goals

- App bundle, Info.plist, DMG.
- Changing the SwiftUI layout.

## 5. Success metrics

- **SM-1**: After `swift run MarkSweep`, a window titled MarkSweep is visible without clicking the Dock.
- **SM-C1**: `swift test` still passes. No Core change required.
