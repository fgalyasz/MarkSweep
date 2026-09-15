# MarkSweep

MarkSweep is a macOS app that marks junk and reclaimable Gmail, then sweeps it to Trash after you review. It does not delete automatically.

Later releases will add iCloud Photos and Google Photos through the same account picker. Google Photos cannot bulk-delete the existing library through the official API.

## Requirements

- macOS 13 Ventura or later
- A Google Cloud OAuth Desktop client with Gmail API enabled (testing mode is enough for private use)

Set `MARKSWEEP_GOOGLE_CLIENT_ID` (and `MARKSWEEP_GOOGLE_CLIENT_SECRET` if the client has one) before connecting Gmail.

## Development

```
swift test
swift run MarkSweep
```

Product work follows [docs/pdlc.md](docs/pdlc.md).
