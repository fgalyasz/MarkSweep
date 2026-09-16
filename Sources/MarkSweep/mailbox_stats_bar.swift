import SwiftUI
import MarkSweepCore

struct StatsMetric: View {
    let title: String
    let value: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
            detailText
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder var detailText: some View {
        if let detail {
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

struct StorageMetric: View {
    let quota: StorageQuota?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Storage")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(storageValue)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
            fillBar
            freeText
        }
        .help(mailboxQuotaNote())
        .accessibilityElement(children: .combine)
    }

    var storageValue: String {
        guard let quota else { return "Unavailable" }
        return storagePairLine(quota)
    }

    @ViewBuilder var fillBar: some View {
        if let quota, let ratio = quotaFillRatio(quota) {
            ProgressView(value: ratio)
                .tint(ratio >= 0.9 ? Color.orange : Color.accentColor)
                .frame(width: 148)
        }
    }

    @ViewBuilder var freeText: some View {
        if let quota, let free = storageFreeLine(quota) {
            Text(free)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct MailboxStatsBar: View {
    let snapshot: MailboxSnapshot
    let visibleCount: Int
    let scannedCount: Int

    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            StatsMetric(
                title: "Mailbox",
                value: mailboxCountLine(snapshot),
                detail: showingCountLine(visible: visibleCount, total: scannedCount)
            )
            StorageMetric(quota: snapshot.quota)
            StatsMetric(title: "This session", value: mailboxCleanedSessionLine(snapshot))
            StatsMetric(title: "All time", value: mailboxCleanedLifetimeLine(snapshot))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
