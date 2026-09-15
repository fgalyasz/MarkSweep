# Addendum — MarkSweep foundation

Mechanism for implementers. FR IDs refer to `prd.md`.

## Layout

- `Sources/MarkSweepCore` — account kinds, OAuth URL/PKCE/token helpers, token store protocol, PhotoSource. No AppKit.
- `Sources/MarkSweep` — SwiftUI, loopback HTTP catcher, Keychain store, browser open.
- Tests cover Core only. Pass `now` into token expiry helpers.

## OAuth

Scopes: `gmail.readonly` and `gmail.modify`. Desktop client. Redirect `http://127.0.0.1:<ephemeral port>/`. `access_type=offline` and `prompt=consent` so a refresh token arrives in testing.

Config: `MARKSWEEP_GOOGLE_CLIENT_ID`, optional `MARKSWEEP_GOOGLE_CLIENT_SECRET`, or Application Support `google_oauth_config.json` copied from the example file.

## Keychain

Service `com.tenprintsoftware.MarkSweep`, account `gmail-oauth`. JSON-encoded `OAuthToken`.

## Settings

`~/Library/Application Support/MarkSweep/settings.json` holds `lastEmail` and scan thresholds used by the next PRD. No tokens.
