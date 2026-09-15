---
title: MarkSweep foundation
status: final
created: 2026-09-15
updated: 2026-09-15
parent_issue: pending
---

# PRD: MarkSweep foundation

Hobby/solo. One user-visible goal: open MarkSweep, pick an account kind, connect Gmail, and see a window ready to scan. Photo sources are visible but not live.

## 1. Vision

TenPrint utilities stay local and explicit. MarkSweep is the cleaner: one Mac app, several cloud accounts, nothing deleted until the user confirms. Foundation is the shell those later sweeps plug into.

## 2. User journeys

- **UJ-1. First launch.** Anna opens MarkSweep. She sees Gmail, iCloud Photos, and Google Photos. Only Gmail is enabled.
- **UJ-2. Connect Gmail.** She chooses Gmail, signs in with Google in the browser, and returns to an account chip with her address. Disconnect clears the session.
- **UJ-3. Coming soon.** She clicks iCloud Photos or Google Photos and reads that those sources ship later. The app does not crash or request Photos permission.
- **UJ-4. Missing client.** Without an OAuth client ID the Connect button explains how to set `MARKSWEEP_GOOGLE_CLIENT_ID`. Tokens are never written to disk as JSON.

## 3. Features

#### FR-1: Windowed app

MarkSweep is a regular Mac window, not a menu-bar-only utility. Quit is explicit. Closing the window can hide the app; it does not scan in the background.

**Consequences:**
- Launch shows a window with an account picker or the connected account.
- No Dock-less accessory policy in this increment.

#### FR-2: Account kinds

The picker lists Gmail, iCloud Photos, and Google Photos. Only Gmail can connect. The other two are disabled with a coming-soon label.

**Consequences:**
- `AccountKind` has three cases. `accountKindIsEnabled` is true only for `.gmail`.
- PhotoKit is not requested.

#### FR-3: Gmail OAuth on loopback

Connect uses Google OAuth 2.0 with PKCE and a `http://127.0.0.1:<port>` redirect. Access and refresh tokens go to Keychain. Disconnect deletes the Keychain item and the in-memory account.

**Consequences:**
- No custom URL scheme required for `swift run`.
- Settings JSON may remember the last email, never the tokens.
- Denied or mismatched `state` leaves the app disconnected.

#### FR-4: PhotoSource stub

Core exposes `PhotoSource` with list, thumbnail, and delete. The only implementation throws `notAvailable`.

**Consequences:**
- UI does not call PhotoSource in this increment except tests.
- Later iCloud and Google adapters implement the same protocol.

#### FR-5: One connected Gmail

One Gmail session at a time. Connecting again replaces the previous token set.

**Consequences:**
- No multi-account switcher yet.
- Profile email is the display name of the session.

## 4. Non-goals

- Scanning or trashing mail (next PRD).
- iCloud or Google Photos deletion.
- Sparkle, DMG, Polar, tenprintsoftware.com listing.
- Google OAuth app verification / CASA.
- Cloud LLM for mail bodies.

## 5. Success metrics

- **SM-1**: A test user listed on the OAuth client can connect and see their Gmail address.
- **SM-C1**: Disconnect leaves Keychain empty for the MarkSweep Gmail item; `swift test` covers PKCE, callback parse, token merge, and PhotoSource stub.
