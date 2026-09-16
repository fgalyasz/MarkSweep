import SwiftUI
import MarkSweepCore

struct ReviewView: View {
    @EnvironmentObject var session: AppSession

    var body: some View {
        NavigationSplitView {
            filterList
        } content: {
            messageList
        } detail: {
            PreviewPane(item: session.selectedItem)
        }
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { sweepBar }
        .alert("Sweep to Trash?", isPresented: $session.confirmSweep) {
            Button("Cancel", role: .cancel) { session.confirmSweep = false }
            Button("Move to Trash", role: .destructive) {
                Task { await session.sweep() }
            }
        } message: {
            Text("Move \(session.plan.count) messages (\(formatBytes(session.plan.bytes))) to Gmail Trash. You can recover them there for about 30 days.")
        }
    }

    var filterList: some View {
        List {
            Section("Account") {
                Text(session.account?.email ?? "")
                Button("Disconnect", action: session.disconnect)
            }
            if let snapshot = session.snapshot {
                Section("Mailbox") {
                    Text(mailboxCountLine(snapshot))
                    Text(mailboxQuotaLine(snapshot))
                    Text(mailboxQuotaNote())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(mailboxCleanedSessionLine(snapshot))
                    Text(mailboxCleanedLifetimeLine(snapshot))
                }
            }
            Section("Filter") {
                Text(showingCountLine(visible: session.visibleItems.count, total: session.items.count))
                    .foregroundStyle(.secondary)
                ForEach(ReviewFilter.allCases) { filter in
                    Button(reviewFilterTitle(filter)) { session.filter = filter }
                        .foregroundStyle(session.filter == filter ? Color.accentColor : Color.primary)
                }
            }
        }
        .frame(minWidth: 180)
    }

    var messageList: some View {
        List(session.visibleItems, selection: $session.selectedID) { item in
            MessageRowView(item: item, isOn: item.selected) {
                session.toggle(id: item.id)
            }
            .tag(item.id)
        }
        .frame(minWidth: 320)
    }

    var sweepBar: some View {
        HStack {
            Text(session.statusText ?? "\(session.items.count) scanned")
            Spacer()
            if let error = session.errorText {
                Text(error).foregroundStyle(.red)
            }
            if session.isBusy { ProgressView() }
            Button("Sweep \(session.plan.count) · \(formatBytes(session.plan.bytes))") {
                session.confirmSweep = session.plan.count > 0
            }
            .disabled(session.isBusy || session.plan.count == 0)
        }
        .padding()
        .background(.bar)
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Scan") { Task { await session.scan() } }
                .disabled(session.isBusy)
        }
        ToolbarItem(placement: .automatic) {
            Button("Select visible") { session.selectVisible(true) }
        }
        ToolbarItem(placement: .automatic) {
            Button("Clear visible") { session.selectVisible(false) }
        }
    }
}
