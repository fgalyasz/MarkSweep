# Epics — keep TTL

1. keepDays on rules, protect vs expire, auto-trash on Scan.

Stories:
- Optional keepDays (nil/blank = forever)
- Protect in-window vs expire past the window
- Auto-trash expired matches on Scan
- Unit coverage for expiry math, upsert days, legacy decode
