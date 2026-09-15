import SwiftUI
import MarkSweepCore

struct ConnectView: View {
    @EnvironmentObject var session: AppSession

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MarkSweep")
                .font(.largeTitle)
            Text("Connect an account. Gmail can scan and sweep to Trash after you review. Photos come later.")
                .foregroundStyle(.secondary)
            ForEach(AccountKind.allCases) { kind in
                accountRow(kind)
            }
            if let error = session.errorText {
                Text(error).foregroundStyle(.red)
            }
            if session.isBusy {
                ProgressView("Waiting for Google…")
            }
        }
        .padding(32)
        .frame(maxWidth: 560, alignment: .leading)
    }

    func accountRow(_ kind: AccountKind) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(accountKindTitle(kind)).font(.headline)
                if let soon = accountKindComingSoon(kind) {
                    Text(soon).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(accountKindIsEnabled(kind) ? "Connect" : "Unavailable") {
                session.choose(kind)
            }
            .disabled(session.isBusy)
        }
        .padding(12)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
    }
}
