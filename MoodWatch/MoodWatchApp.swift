import SwiftUI

@main
struct MoodWatchApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Theme.mint)
                .preferredColorScheme(nil)
        }
    }
}
