import SwiftUI

@main
struct AppleWatchApp: App {
    @StateObject private var vm = WatchArticlesViewModel()

    var body: some Scene {
        WindowGroup {
            WatchOverviewView()
                .environmentObject(vm)
        }
    }
}
