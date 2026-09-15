# Addendum — MarkSweep Gmail sweep

Mechanism for implementers. FR IDs refer to `prd.md`.

## Queries

`gmailScanQueries(largeMegabytes:)` returns:

- `in:spam`
- `category:promotions`
- `category:social`
- `larger:<N>M` where N is at least 1
- `in:inbox newer_than:365d`

`collectIds` paginates each query until `nextPageToken` is missing or the cap is hit, then `uniqueIds`.

## Classifier order

1. Label `SPAM` → spamLike "Gmail spam"
2. `CATEGORY_PROMOTIONS` → spamLike "Promotions"
3. `CATEGORY_SOCIAL` → spamLike "Social"
4. `List-Unsubscribe` present → spamLike "Newsletter"
5. `sizeEstimate >= largeBytes` → large "Large message"
6. Phrase match in subject/snippet/body → suspect with the matched phrase
7. Else keep "Looks personal"

Phrase lists live in `harassment_signals.swift`. Match is case-insensitive `contains` on the joined text.

## Gmail HTTP

Base `https://gmail.googleapis.com/gmail/v1/users/me`. Inject `HTTPTransporting`. `batchModify` body `{"ids":[...],"addLabelIds":["TRASH"]}`. Chunk size 1000.

Metadata GET uses `format=metadata` and headers From, Subject, Date, List-Unsubscribe. Full GET uses `format=full`.

## Preview

`stripTags` drops `script`/`style` blocks then tags. `collapseWhitespace`. `truncate` 800 chars.
