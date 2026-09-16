# Changelog

## 0.1.11 — 2026-09-16

- Connect stores Gmail tokens in Application Support so unsigned `swift run` can finish sign-in. The data-protection keychain add was failing and looked like a Gmail decode error.

## 0.1.10 — 2026-09-16

- Keep rules can keep matching mail for a set number of days. Empty Days means forever. After the window, Scan moves those messages to Trash.

## 0.1.9 — 2026-09-16

- Gmail tokens use the data-protection keychain so `swift run` does not ask for the login password every launch.

## 0.1.8 — 2026-09-16

- Keep rules: delete button, right-click a message to add From/To/Subject, and no duplicate rows.

## 0.1.7 — 2026-09-16

- Keep rules: From, To, Cc, Subject, Body — exact or contains. Matching mail is never swept. Edit rules in the app.

## 0.1.6 — 2026-09-16

- Stats header keeps full digits at the default window size. Metrics wrap instead of showing ellipsis; storage shows used bytes as the headline.

## 0.1.5 — 2026-09-16

- Review chrome is Mail-like: filters in the sidebar with counts, mailbox/storage/cleaned in a header above the list.

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
