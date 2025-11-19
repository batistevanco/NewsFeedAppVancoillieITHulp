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

    /// Plan een dagelijkse herhalende melding om 17:00, ongeacht het aantal nieuwe artikels.
    /// Roept **geen** OS-prompt aan; ga er dus van uit dat de caller dat al geregeld heeft.
    func scheduleDaily() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // Controleer of we meldingen mogen tonen
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional ||
                  settings.authorizationStatus == .ephemeral else {
                return // geen toestemming → niet plannen
            }

            Task { @MainActor in
                let identifier = "news.daily.17"

                // Verwijder eventueel bestaande requests met dezelfde identifier
                UNUserNotificationCenter.current()
                    .removePendingNotificationRequests(withIdentifiers: [identifier])

                // Simpele, generieke inhoud voor de dagelijkse reminder
                let content = UNMutableNotificationContent()
                content.title = "Vancoillie News"
                content.body = NSLocalizedString("notification_daily_body", comment: "Daily reminder body text")
                content.sound = .default

                // Elke dag om 17:00
                var comps = DateComponents()
                comps.hour = 17
                comps.minute = 0

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: comps,
                    repeats: true
                )

                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )

                try? await UNUserNotificationCenter.current().add(request)
            }
        }
    }

    /// Annuleer alle nog niet afgeleverde meldingen.
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
