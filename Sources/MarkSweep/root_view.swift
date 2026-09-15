import SwiftUI
import MarkSweepCore

struct RootView: View {
    @EnvironmentObject var session: AppSession

    var body: some View {
        Group {
            if session.account == nil {
                ConnectView()
            } else {
                ReviewView()
            }
        }
        .onAppear(perform: becomeRegularApp)
        .alert(
            "Coming soon",
            isPresented: Binding(
                get: { session.comingSoonKind != nil },
                set: { if $0 == false { session.comingSoonKind = nil } }
            )
        ) {
            Button("OK", role: .cancel) { session.comingSoonKind = nil }
        } message: {
            Text(comingSoonMessage(session.comingSoonKind))
        }
    }
}

func comingSoonMessage(_ kind: AccountKind?) -> String {
    switch kind {
    case .iCloudPhotos:
        return "iCloud Photos will use PhotoKit on the photos you mark. Not in this version."
    case .googlePhotos:
        return "Google Photos can only analyze photos you pick. The official API cannot delete your library."
    default:
        return "This account type is not available yet."
    }
}
