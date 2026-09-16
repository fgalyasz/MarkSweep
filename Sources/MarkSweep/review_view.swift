import SwiftUI
import MarkSweepCore

struct ReviewView: View {
    @EnvironmentObject var session: AppSession
    @State private var showKeepRules = false

    var body: some View {
        NavigationSplitView {
            FilterSidebar(showKeepRules: $showKeepRules)
        } content: {
            messageColumn
        } detail: {
            PreviewPane(item: session.selectedItem)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 340)
        }
        .sheet(isPresented: $showKeepRules) {
            KeepRulesView()
                .environmentObject(session)
        }
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { SweepBar() }
        .alert("Sweep to Trash?", isPresented: $session.confirmSweep) {
            Button("Cancel", role: .cancel) { session.confirmSweep = false }
            Button("Move to Trash", role: .destructive) {
                Task { await session.sweep() }
            }
        } message: {
            Text("Move \(session.plan.count) messages (\(formatBytes(session.plan.bytes))) to Gmail Trash. You can recover them there for about 30 days.")
        }
    }

    var messageColumn: some View {
        VStack(spacing: 0) {
            if let snapshot = session.snapshot {
                MailboxStatsBar(
                    snapshot: snapshot,
                    visibleCount: session.visibleItems.count,
                    scannedCount: session.items.count
                )
                Divider()
            }
            messageList
        }
        .navigationSplitViewColumnWidth(min: 400, ideal: 560)
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

struct FilterSidebar: View {
    @EnvironmentObject var session: AppSession
    @Binding var showKeepRules: Bool

    var body: some View {
        VStack(spacing: 0) {
            accountHeader
            Divider()
            filterList
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 228, max: 280)
    }

    var accountHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.account?.email ?? "")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            Button("Disconnect", action: session.disconnect)
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            Button("Keep rules (\(session.settings.keepRules.count))") {
                showKeepRules = true
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var filterList: some View {
        List(selection: $session.filter) {
            Section("Filter") {
                ForEach(ReviewFilter.allCases) { filter in
                    FilterCountRow(filter: filter, count: matchingCount(session.items, filter: filter))
                }
            }
        }
        .listStyle(.sidebar)
    }
}

struct FilterCountRow: View {
    let filter: ReviewFilter
    let count: Int

    var body: some View {
        HStack {
            Text(reviewFilterTitle(filter))
            Spacer()
            Text(formatCount(count))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .tag(filter)
    }
}

struct SweepBar: View {
    @EnvironmentObject var session: AppSession

    var body: some View {
        HStack(spacing: 12) {
            Text(session.statusText ?? "\(session.items.count) scanned")
                .foregroundStyle(.secondary)
            Spacer()
            errorLabel
            if session.isBusy { ProgressView().controlSize(.small) }
            sweepButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    @ViewBuilder var errorLabel: some View {
        if let error = session.errorText {
            Text(error).foregroundStyle(.red).lineLimit(1)
        }
    }

    var sweepButton: some View {
        Button("Sweep \(session.plan.count) · \(formatBytes(session.plan.bytes))") {
            session.confirmSweep = session.plan.count > 0
        }
        .disabled(session.isBusy || session.plan.count == 0)
    }
}
