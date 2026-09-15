import AppKit
import SwiftUI

@main
struct MarkSweepApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var session = AppSession()

    var body: some Scene {
        WindowGroup("MarkSweep") {
            RootView()
                .environmentObject(session)
                .frame(minWidth: 840, minHeight: 520)
                .onAppear(perform: becomeRegularApp)
        }
    }
}
