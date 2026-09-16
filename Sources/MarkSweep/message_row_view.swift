import SwiftUI
import MarkSweepCore

struct MessageRowView: View {
    let item: ReviewItem
    let isOn: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Toggle("", isOn: Binding(get: { isOn }, set: { _ in onToggle() }))
                .labelsHidden()
                .toggleStyle(.checkbox)
                .disabled(item.isProtected)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.subject.isEmpty ? "(no subject)" : item.subject)
                    .font(.headline)
                    .lineLimit(1)
                Text(item.sender)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack {
                    Text(item.reason)
                    Spacer()
                    Text(formatBytes(item.sizeBytes))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
