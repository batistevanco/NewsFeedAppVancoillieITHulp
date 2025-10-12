import SwiftUI

@main
struct VancoillieNewsAppApp: App {
    @AppStorage("notifications.enabled") private var notificationsEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("app.theme") private var themeRaw: String = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
                    RootView()
                        .preferredColorScheme(AppTheme(rawValue: themeRaw)?.colorScheme)
                }
        .onChange(of: scenePhase) {
            if scenePhase == .active, notificationsEnabled {
                NotificationManager.shared.scheduleDaily()
            }
        }
    }
}
