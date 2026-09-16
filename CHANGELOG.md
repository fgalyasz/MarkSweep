# Changelog

## 0.1.4 — 2026-09-16

- Sidebar shows mailbox message count, Google storage used vs plan, and cleaned totals. Showing A of B so a filter is not mistaken for the whole scan.
- Connect also asks for Drive metadata (shared Gmail/Drive/Photos quota). Disconnect and Connect again after enabling the Drive API.

## 0.1.3 — 2026-09-15

- Scan paces Gmail calls and keeps partial results when the per-minute quota is hit. Default cap is 40 per query.

## 0.1.2 — 2026-09-15

- After Google sign-in, a 403 names the cause. If Gmail API is off, the app tells you to enable it.

## 0.1.1 — 2026-09-15

- `swift run MarkSweep` brings a window to the front. An unbundled process no longer sits in the terminal with no UI.

## 0.1.0 — 2026-09-15

- Windowed app with an account picker. Gmail connects; iCloud Photos and Google Photos show as coming soon.
- Gmail scan marks spam-like, large, and suspect mail. Review, then sweep selected messages to Trash.
- Storage estimate for the selected sweep. Tokens stay in Keychain. Mail bodies stay on-device.
