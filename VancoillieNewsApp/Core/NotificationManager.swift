import Foundation
import UserNotifications



/// Centrale helper voor lokaal plannen/annuleren van de dagelijkse nieuws-melding.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Rechten

    /// Vraag OS-rechten **alleen** als de status nog onbekend is.
    /// - Returns via completion of het OS *meldingen mag tonen* (authorized/provisional/ephemeral).
    func requestIfNeeded(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                        completion(granted)
                    }
            case .authorized, .provisional, .ephemeral:
                completion(true)
            default:
                completion(false)
            }
        }
    }

    // MARK: - Plannen / annuleren

    /// Plan de dagelijkse melding (één-shot) voor de volgende 17:00.
    /// Roept **geen** OS-prompt aan; ga er dus van uit dat de caller dat al geregeld heeft.
    func scheduleDaily() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self else { return }
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional ||
                  settings.authorizationStatus == .ephemeral else {
                return // geen toestemming → niet plannen
            }

            Task {
                let content = await self.buildContentForToday()
                let identifier = "news.daily.17"

                // voorkom dubbele requests met dezelfde id
                UNUserNotificationCenter.current()
                    .removePendingNotificationRequests(withIdentifiers: [identifier])

                let trigger = UNCalendarNotificationTrigger(dateMatching: self.nextFivePM(), repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                // iOS 17+ heeft async add; met try? om falen niet te crashen
                try? await UNUserNotificationCenter.current().add(request)
            }
        }
    }

    /// Annuleer alle nog niet afgeleverde meldingen.
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers voor 17:00-venster

    /// Volgende 17:00 in DateComponents (vandaag als het nog moet komen, anders morgen).
    nonisolated private func nextFivePM() -> DateComponents {
        let cal = Calendar.current
        let now = Date()

        var today = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        today.hour = 17
        today.minute = 0
        today.second = 0

        if let todayAtFive = cal.date(from: today), todayAtFive > now {
            return cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: todayAtFive)
        } else {
            let tomorrow = cal.date(byAdding: .day, value: 1, to: now)!
            var comp = cal.dateComponents([.year, .month, .day], from: tomorrow)
            comp.hour = 17
            comp.minute = 0
            comp.second = 0
            return comp
        }
    }

    /// Venster [laatste 17:00, nu] om te tellen hoeveel nieuwe artikels er zijn.
   nonisolated private func windowSinceLastFivePM() -> (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()

        var base = cal.dateComponents([.year, .month, .day], from: now)
        base.hour = 17
        base.minute = 0
        base.second = 0
        let todayAtFive = cal.date(from: base)!

        let start: Date = (now >= todayAtFive) ? todayAtFive
                                               : cal.date(byAdding: .day, value: -1, to: todayAtFive)!
        return (start, now)
    }

    // MARK: - Content opbouwen

    /// Bouwt de meldingstitel/body dynamisch op basis van het aantal nieuwe artikels sinds 17:00.
    /// Houdt rekening met de app-taal (UserDefaults "app.language") met fallback op systeem.
    private func buildContentForToday() async -> UNMutableNotificationContent {
        // Bepaal taalcode
        let langPref = UserDefaults.standard.string(forKey: "app.language")
        let localeCode: String = {
            if let lp = langPref, (lp == "en" || lp == "nl") { return lp }
            // Fallback op systeem
            if let sys = Locale.preferredLanguages.first, sys.starts(with: "en") { return "en" }
            return "nl"
        }()

        // Haal artikels op in de juiste taal
        let articles = (try? await APIClient.shared.fetchArticles(locale: localeCode, categoryID: nil)) ?? []

        // Tel nieuwe artikels in het 17:00-venster
        let window = windowSinceLastFivePM()
        let count = articles.filter { $0.date >= window.start && $0.date <= window.end }.count

        let content = UNMutableNotificationContent()

        // Lokale keys (zorg dat deze in je Localizable.strings staan)
        let titleKey = "notif.title_app"
        let oneKey   = "notif.one"
        let manyKey  = "notif.many"

        // Titel
        let defaultTitle = "Vancoillie News"
        content.title = NSLocalizedString(titleKey,
                                          tableName: nil,
                                          bundle: .main,
                                          value: defaultTitle,
                                          comment: "")

        // Body
        if count == 1 {
            let fallback = (localeCode == "en") ? "There is 1 new article." : "Er is 1 nieuw artikel."
            content.body = NSLocalizedString(oneKey,
                                             tableName: nil,
                                             bundle: .main,
                                             value: fallback,
                                             comment: "")
        } else {
            let fmtFallback = (localeCode == "en") ? "There are %d new articles." : "Er zijn %d nieuwe artikelen."
            let fmt = NSLocalizedString(manyKey,
                                        tableName: nil,
                                        bundle: .main,
                                        value: fmtFallback,
                                        comment: "")
            content.body = String(format: fmt, count)
        }

        content.sound = .default
        return content
    }
}
