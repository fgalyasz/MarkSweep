# Addendum — MarkSweep mailbox stats

Gmail: `GET .../users/me/profile` → `emailAddress`, `messagesTotal`.

Drive: `GET https://www.googleapis.com/drive/v3/about?fields=storageQuota`. Quota numbers are JSON strings. Scope `https://www.googleapis.com/auth/drive.metadata.readonly`.

Trash still occupies Google storage until emptied. Session counters live on `AppSession`. Lifetime on `MarkSweepSettings.sweptCount` / `sweptBytes`.

Enable Drive API on the same Cloud project as Gmail.
