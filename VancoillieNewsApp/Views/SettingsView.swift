//
//  SettingsView.swift
//  VancoillieNewsApp
//
//  Opgelost: geen geneste trailing-closures in Form; alles via async/await
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    // Notificaties / Thema / Taal
    @AppStorage("notifications.enabled") private var notificationsEnabled = false
    @AppStorage("app.theme") private var themeRaw: String = AppTheme.system.rawValue
    @AppStorage("app.language") private var languageRaw: String = "nl"

    @State private var showSettingsAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Notifications
                Section(header: Text(NSLocalizedString("settings.notifications", comment: ""))) {
                    Toggle(NSLocalizedString("settings.push", comment: ""),
                           isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            // Gebruik Task + async helper (geen nested trailing closures)
                            Task { await handleNotificationsToggle(newValue) }
                        }

                    Text(NSLocalizedString("settings.push_info", comment: ""))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Language
                Section(header: Text(NSLocalizedString("settings.language", comment: ""))) {
                    Picker(NSLocalizedString("settings.language_picker", comment: ""),
                           selection: $languageRaw) {
                        Text(NSLocalizedString("lang.nl", comment: "")).tag("nl")
                        Text(NSLocalizedString("lang.en", comment: "")).tag("en")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: languageRaw) { _, _ in
                        NotificationCenter.default.post(name: .appLanguageChanged, object: nil)
                    }
                }

                // MARK: - Appearance
                Section(header: Text(NSLocalizedString("settings.appearance", comment: ""))) {
                    Picker(NSLocalizedString("settings.theme", comment: ""), selection: $themeRaw) {
                        ForEach(AppTheme.allCases) { t in
                            Text(t.localizedLabel).tag(t.rawValue)
                        }
                    }
                }

                // MARK: - About / Build version
                Section(footer: Text("Made by Vancoillie Studio")) {
                    HStack {
                        Text("App name")
                        Spacer()
                        Text(appName)
                    }
                    HStack {
                        Text(NSLocalizedString("settings.version", comment: ""))
                        Spacer()
                        Text(versionString)
                    }
                }

                // MARK: - Support & Privacy
                Section(header: Text(NSLocalizedString("settings.support", comment: ""))) {
                    Button {
                        if let url = URL(string: "mailto:info@vancoillieithulp.be") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
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
                    primaryButton: .default(Text(NSLocalizedString("notif.settings_open", comment: ""))) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    secondaryButton: .cancel(Text(NSLocalizedString("general.cancel", comment: "")))
                )
            }
            // Eerste sync: toon juiste toggle-stand obv OS-permissie
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

    // MARK: - Helpers (async, geen trailing closures in Form)

    private func handleNotificationsToggle(_ isOn: Bool) async {
        if isOn {
            // Check huidige status
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .notDetermined:
                // Vraag OS-prompt via NotificationManager (bridge -> async)
                let granted = await requestPermissionAsync()
                await MainActor.run {
                    if granted {
                        NotificationManager.shared.scheduleDaily()
                        notificationsEnabled = true
                    } else {
                        notificationsEnabled = false
                    }
                }

            case .denied:
                // Toon “open Instellingen”
                await MainActor.run {
                    notificationsEnabled = false
                    showSettingsAlert = true
                }

            case .authorized, .provisional, .ephemeral:
                // Reeds toestemming -> plan meteen
                NotificationManager.shared.scheduleDaily()

            @unknown default:
                await MainActor.run { notificationsEnabled = false }
            }
        } else {
            // Toggle uit -> annuleer alles
            NotificationManager.shared.cancelAll()
        }
    }

    /// Bridge van de completion-based API naar async/await
    private func requestPermissionAsync() async -> Bool {
        await withCheckedContinuation { continuation in
            NotificationManager.shared.requestIfNeeded { granted in
                continuation.resume(returning: granted)
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

    private var appName: String {
        if let display = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !display.isEmpty {
            return display
        }
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "—"
    }
}

