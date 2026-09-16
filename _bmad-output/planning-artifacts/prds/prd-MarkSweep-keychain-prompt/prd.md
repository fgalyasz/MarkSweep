---
title: MarkSweep keychain prompt
status: final
created: 2026-09-16
updated: 2026-09-16
parent_issue: 54
---

# PRD: MarkSweep keychain prompt

Hobby/solo. One user-visible goal: launching with `swift run` does not ask for the login keychain password every time, even after Always Allow.

## 1. Vision

Always Allow is tied to the binary’s code signature. `swift run` rebuilds an ad-hoc signed executable, so macOS treats it as a new app. The login-keychain ACL dialog returns. Tokens move to the data-protection keychain, which does not use that ACL.

## 2. User journeys

- **UJ-1. After update.** First launch may look disconnected. Connect Gmail once. No keychain password dialog.
- **UJ-2. Later launches.** Restore session from Keychain without a prompt.

## 3. Features

#### FR-1: Data-protection keychain

Load, save, and delete queries set `kSecUseDataProtectionKeychain` to true.

**Consequences:**
- Old login-keychain items are not read (avoids one more prompt).
- Ferenc reconnects once.

## 4. Non-goals

- Signed .app / Developer ID in this increment.
- Migrating the old item (that would prompt).

## 5. Success metrics

- **SM-1**: After one Connect, `swift run` does not show the login keychain dialog.
- **SM-C1**: Query helpers include the data-protection flag; `swift test` green.
