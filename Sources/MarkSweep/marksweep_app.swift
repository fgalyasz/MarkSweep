import AppKit
import SwiftUI

@main
struct MarkSweepApp: App {
    @StateObject private var session = AppSession()

    var body: some Scene {
        WindowGroup("MarkSweep") {
            RootView()
                .environmentObject(session)
                .frame(minWidth: 840, minHeight: 520)
        }
    }
}
