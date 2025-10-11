//
//  SettingsView.swift
//  VancoillieNewsApp
//
//  Updated to always schedule a daily notification at 17:00
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("notifications.enabled") private var notificationsEnabled = false
    @AppStorage("app.theme") private var themeRaw: String = AppTheme.system.rawValue
    @State private var showSettingsAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Notifications
                Section(header: Text(NSLocalizedString("settings.notifications", comment: ""))) {
                    Toggle(NSLocalizedString("settings.push", comment: ""), isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, on in
                            if on {
                                UNUserNotificationCenter.current().getNotificationSettings { settings in
                                    switch settings.authorizationStatus {
                                    case .notDetermined:
                                        NotificationManager.shared.requestIfNeeded { granted in
                                            DispatchQueue.main.async {
                                                if granted {
                                                    NotificationManager.shared.scheduleDaily(title: "", body: "", hour: 17, minute: 0)
                                                } else {
                                                    notificationsEnabled = false
                                                }
                                            }
                                        }
                                    case .denied:
                                        DispatchQueue.main.async {
                                            notificationsEnabled = false
                                            showSettingsAlert = true
                                        }
                                    case .authorized, .provisional, .ephemeral:
                                        NotificationManager.shared.scheduleDaily(title: "", body: "", hour: 17, minute: 0)
                                    @unknown default:
                                        DispatchQueue.main.async {
                                            notificationsEnabled = false
                                        }
                                    }
                                }
                            } else {
                                NotificationManager.shared.cancelAll()
                            }
                        }

                    Text(NSLocalizedString("settings.push_info", comment: ""))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // MARK: Appearance
                Section(header: Text(NSLocalizedString("settings.appearance", comment: ""))) {
                    Picker(NSLocalizedString("settings.theme", comment: ""), selection: $themeRaw) {
                        ForEach(AppTheme.allCases) { t in
                            Text(t.localizedLabel).tag(t.rawValue)
                        }
                    }
                }

                // MARK: Build version
                Section(footer: Text("Vancoillie IT Hulp")) {
                    HStack {
                        Text(NSLocalizedString("settings.version", comment: ""))
                        Spacer()
                        Text(versionString)
                    }
                }

                // MARK: Support & Privacy
                Section(header: Text(NSLocalizedString("settings.support", comment: ""))) {
                    Button(action: {
                        if let url = URL(string: "mailto:info@vancoillieithulp.be") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    Link(destination: URL(string: "https://www.vancoillieithulp.be/newsfeedAppPolicy.html")!) {
                        Label("Privacybeleid", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle(NSLocalizedString("settings.title", comment: ""))
            .alert(isPresented: $showSettingsAlert) {
                Alert(
                    title: Text(NSLocalizedString("notif.settings_title", comment: "")),
                    message: Text(NSLocalizedString("notif.settings_msg", comment: "")),
                    primaryButton: .default(Text(NSLocalizedString("notif.settings_open", comment: "")), action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }),
                    secondaryButton: .cancel(Text(NSLocalizedString("general.cancel", comment: "")))
                )
            }
            .task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                await MainActor.run {
                    switch settings.authorizationStatus {
                    case .authorized, .provisional, .ephemeral:
                        notificationsEnabled = true
                    default:
                        notificationsEnabled = false
                    }
                }
            }
        }
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        if let build, !build.isEmpty {
            return "\(version) (\(build))"
        }
        return version
    }
}
