import SwiftUI
import MarkSweepCore

struct StatsMetric: View {
    let title: String
    let value: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            metricTitle(title)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .fixedSize(horizontal: true, vertical: false)
            detailText
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder var detailText: some View {
        if let detail {
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

func metricTitle(_ title: String) -> some View {
    Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: true, vertical: false)
}

struct StorageMetric: View {
    let quota: StorageQuota?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            metricTitle("Storage")
            Text(storageValue)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .fixedSize(horizontal: true, vertical: false)
            limitCaption
            fillBar
            freeText
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .help(mailboxQuotaNote())
        .accessibilityElement(children: .combine)
    }

    var storageValue: String {
        guard let quota else { return "Unavailable" }
        return storageHeadline(quota)
    }

    @ViewBuilder var limitCaption: some View {
        if let quota, let detail = storageDetailLine(quota) {
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    @ViewBuilder var fillBar: some View {
        if let quota, let ratio = quotaFillRatio(quota) {
            ProgressView(value: ratio)
                .tint(ratio >= 0.9 ? Color.orange : Color.accentColor)
        }
    }

    @ViewBuilder var freeText: some View {
        if let quota, let free = storageFreeLine(quota) {
            Text(free)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

struct MailboxStatsBar: View {
    let snapshot: MailboxSnapshot
    let scannedCount: Int

    var body: some View {
        LazyVGrid(columns: statsBarColumns, alignment: .leading, spacing: 12) {
            StatsMetric(
                title: "Mailbox",
                value: mailboxCountLine(snapshot),
                detail: scannedOfMailboxLine(scanned: scannedCount, mailbox: snapshot.messagesTotal)
            )
            StorageMetric(quota: snapshot.quota)
            StatsMetric(title: "This session", value: mailboxCleanedSessionLine(snapshot))
            StatsMetric(title: "All time", value: mailboxCleanedLifetimeLine(snapshot))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

let statsBarColumns = [
    GridItem(.adaptive(minimum: 168), spacing: 16, alignment: .topLeading)
]
