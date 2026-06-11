//
//  RootView.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 10/10/2025.
//


import SwiftUI
import UserNotifications

struct RootView: View {
    @AppStorage("notif.prompted") private var notifPrompted = false
    @AppStorage("notifications.enabled") private var notificationsEnabled = false
    @AppStorage("onboarding.completed") private var onboardingCompleted = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Group {
                if DeviceLayout.isPad {
                    IPadHomeView(selectedTab: $selectedTab)
                } else {
                    HomeView(selectedTab: $selectedTab)
                }
            }
                .tag(0)
                .tabItem { Label(NSLocalizedString("tab.home", comment: ""), systemImage: "house") }

            Group {
                if DeviceLayout.isPad {
                    IPadArticlesView()
                } else {
                    ArticlesView()
                }
            }
                .tag(1)
                .tabItem { Label(NSLocalizedString("tab.articles", comment: ""), systemImage: "newspaper") }

            SettingsView()
                .tag(2)
                .tabItem { Label(NSLocalizedString("tab.settings", comment: ""), systemImage: "gearshape") }
        }
        .tint(Brand.blue)
        .fullScreenCover(isPresented: Binding(
            get: { !onboardingCompleted },
            set: { if !$0 { onboardingCompleted = true } }
        )) {
            OnboardingView()
        }

        // ▼ vraag OS-prompt direct bij eerste run (of als nooit gevraagd)
                .task {
                    // Vraag alleen als nog nooit gevraagd én status nog onbekend
                    let settings = await UNUserNotificationCenter.current().notificationSettings()
                    if settings.authorizationStatus == .notDetermined && !notifPrompted {
                        // Toon OS-prompt
                        NotificationManager.shared.requestIfNeeded { granted in
                            DispatchQueue.main.async {
                                self.notifPrompted = true
                                self.notificationsEnabled = granted
                                if granted {
                                    // Plan meteen de dagelijkse melding om 17:00
                                    NotificationManager.shared.scheduleDaily()
                                }
                            }
                        }
                    } else {
                        // Status was al beslist: sync de toggle voor consistentie
                        await MainActor.run {
                            self.notificationsEnabled = (settings.authorizationStatus == .authorized
                                                         || settings.authorizationStatus == .provisional
                                                         || settings.authorizationStatus == .ephemeral)
                        }
                    }
                }
    }
}
