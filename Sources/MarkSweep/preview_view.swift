import SwiftUI
import MarkSweepCore

struct PreviewPane: View {
    let item: ReviewItem?

    var body: some View {
        Group {
            if let item {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.subject.isEmpty ? "(no subject)" : item.subject)
                            .font(.title2)
                        Text(item.sender)
                        Text(item.date.formatted())
                        Text("\(verdictLabel(item.verdict)) · \(item.reason)")
                            .foregroundStyle(.secondary)
                        if item.isProtected {
                            Text("Protected — never swept.")
                                .foregroundStyle(.secondary)
                        }
                        Divider()
                        Text(item.preview.isEmpty ? "No preview." : item.preview)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            } else {
                Text("Scan Gmail to review messages.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 220)
    }
}

func verdictLabel(_ kind: MessageVerdictKind) -> String {
    switch kind {
    case .keep: return "Keep"
    case .suspect: return "Suspect"
    case .spamLike: return "Spam-like"
    case .large: return "Large"
    }
}
