---
title: MarkSweep connect decode
status: final
created: 2026-09-16
updated: 2026-09-16
parent_issue: 62
---

# PRD: MarkSweep connect decode

Hobby/solo. One user-visible goal: Connect Gmail succeeds after Google sign-in. The red “Could not read a Gmail or OAuth response” must not appear when the token cannot be stored.

## 1. Vision

`swift run` is ad-hoc signed. `kSecUseDataProtectionKeychain` add returns `errSecMissingEntitlement` (-34018). Save was mapped to `decode`, so Connect looked like a Gmail parse failure. Tokens belong in Application Support next to settings, not in Keychain, until a signed .app exists.

## 2. User journeys

- **UJ-1. Connect.** Browser sign-in, then Review. No decode error.
- **UJ-2. Relaunch.** Last email restores from the token file without a keychain password dialog.

## 3. Features

#### FR-1: File token store

Default `TokenStoring` reads and writes `Application Support/MarkSweep/gmail_oauth_token.json` (atomic, mode 0600). Missing or corrupt file loads as disconnected.

**Consequences:**
- Keychain is unused on the Connect path.
- Old login-keychain items are not read (avoids the ACL prompt).

#### FR-2: Actionable save failure

A write failure is `tokenSaveFailed`, not `decode`. Copy names Application Support/MarkSweep.

**Consequences:**
- Real Google JSON failures still use `decode`.

## 4. Non-goals

- Signed .app / Developer ID.
- Migrating or deleting the old Keychain item (that can prompt).

## 5. Success metrics

- **SM-1**: Connect after Google consent lands on Review.
- **SM-C1**: File store round-trip, missing, corrupt, save failure; `swift test` green.
