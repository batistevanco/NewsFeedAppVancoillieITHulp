//
//  SettingsView.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 10/10/2025.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage("notifications.enabled") private var notificationsEnabled = true
    @AppStorage("notifications.hour") private var notifHour: Int = 9
    @AppStorage("notifications.minute") private var notifMinute: Int = 0
    @AppStorage("app.theme") private var themeRaw: String = AppTheme.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(NSLocalizedString("settings.notifications", comment: ""))) {
                        Toggle(NSLocalizedString("settings.push", comment: ""), isOn: $notificationsEnabled)
                            .onChange(of: notificationsEnabled) { _, on in
                                if on {
                                    NotificationManager.shared.requestIfNeeded()
                                    scheduleLatestNotificationAtCurrentTime()
                                } else {
                                    NotificationManager.shared.cancelAll()
                                }
                            }

                        DatePicker(selection: bindingForTime(), displayedComponents: .hourAndMinute) {
                            Text(NSLocalizedString("settings.time", comment: ""))
                        }
                        .onChange(of: notifHour) { _, _ in
                            reschedule()
                        }
                        .onChange(of: notifMinute) { _, _ in
                            reschedule()
                        }
                    }

                Section(header: Text(NSLocalizedString("settings.appearance", comment: ""))) {
                    Picker(NSLocalizedString("settings.theme", comment: ""), selection: $themeRaw) {
                        ForEach(AppTheme.allCases) { t in
                            Text(t.localizedLabel).tag(t.rawValue)
                        }
                    }
                }

                Section(footer: Text("Vancoillie IT Hulp")) {
                    HStack {
                        Text(NSLocalizedString("settings.version", comment: ""))
                        Spacer()
                        Text(versionString)
                    }
                }

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
        }
    }
    
    private func scheduleLatestNotificationAtCurrentTime() {
        Task {
            do {
                let articles = try await APIClient.shared.fetchArticles(
                    locale: LocaleHelper.appLangParam,
                    categoryID: nil
                )
                let latest = articles.first
                let title = latest?.title ?? "Vancoillie IT Hulp"
                // Kort de body eventueel in zodat de banner mooi past
                let body = latest?.description != nil
                               ? String(latest!.description.prefix(100)) + "…"
                               : "Nieuwe artikels zijn beschikbaar."

                NotificationManager.shared.scheduleDaily(
                    title: title,
                    body: body,
                    hour: notifHour,
                    minute: notifMinute
                )
            } catch {
                // Fallback bij fout of geen internet
                NotificationManager.shared.scheduleDaily(
                    title: "Vancoillie IT Hulp",
                    body: "Nieuwe artikels zijn beschikbaar.",
                    hour: notifHour,
                    minute: notifMinute
                )
            }
        }
    }

    private func bindingForTime() -> Binding<Date> {
        Binding<Date>(
            get: {
                var comps = DateComponents()
                comps.hour = notifHour; comps.minute = notifMinute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                notifHour = comps.hour ?? 9
                notifMinute = comps.minute ?? 0
            }
        )
    }

    private func reschedule() {
        guard notificationsEnabled else { return }
        NotificationManager.shared.cancelAll()
        scheduleLatestNotificationAtCurrentTime()
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
