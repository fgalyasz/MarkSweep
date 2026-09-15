# Addendum — MarkSweep swift run window

Mechanism for implementers. FR IDs refer to `prd.md`.

`AppDelegate.applicationDidFinishLaunching` calls `becomeRegularApp()`. `RootView.onAppear` calls it again so the WindowGroup window exists before `orderFront`. Policy is `.regular`. Activate with `ignoringOtherApps: true` (macOS 13). Then `NSApp.windows.forEach { $0.makeKeyAndOrderFront(nil) }`.
