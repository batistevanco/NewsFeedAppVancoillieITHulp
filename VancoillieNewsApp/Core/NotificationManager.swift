import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager(); private init(){}

    func requestIfNeeded(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    completion(granted)
                }
            } else {
                completion(settings.authorizationStatus == .authorized ||
                           settings.authorizationStatus == .provisional ||
                           settings.authorizationStatus == .ephemeral)
            }
        }
    }

    func scheduleDaily(title: String, body: String, hour: Int, minute: Int) {
        Task {
            let content = await buildContentForToday()
            let identifier = "news.daily.17"
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            let trigger = UNCalendarNotificationTrigger(dateMatching: nextFivePM(), repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func nextFivePM() -> DateComponents {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        components.hour = 17
        components.minute = 0
        components.second = 0
        if let todayFivePM = calendar.date(from: components), todayFivePM > now {
            return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: todayFivePM)
        } else {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
            var tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            tomorrowComponents.hour = 17
            tomorrowComponents.minute = 0
            tomorrowComponents.second = 0
            return tomorrowComponents
        }
    }

    private func windowSinceLastFivePM() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 17
        components.minute = 0
        components.second = 0
        let todayFivePM = calendar.date(from: components)!
        let start: Date
        if now >= todayFivePM {
            start = todayFivePM
        } else {
            start = calendar.date(byAdding: .day, value: -1, to: todayFivePM)!
        }
        return (start: start, end: now)
    }

    private func buildContentForToday() async -> UNMutableNotificationContent {
        let localeCode: String
        if let lang = Locale.preferredLanguages.first, lang.starts(with: "en") {
            localeCode = "en"
        } else {
            localeCode = "nl"
        }

        let articles = (try? await APIClient.shared.fetchArticles(locale: "nl", categoryID: nil)) ?? []
        let window = windowSinceLastFivePM()
        let count = articles.filter { article in
            article.date >= window.start && article.date <= window.end
        }.count

        let content = UNMutableNotificationContent()
        let titleKey = "notif.title_app"
        let oneKey = "notif.one"
        let manyKey = "notif.many"

        let title = NSLocalizedString(titleKey, tableName: nil, bundle: .main, value: localeCode == "en" ? "Vancoillie News" : "Vancoillie News", comment: "")
        content.title = title

        if count == 1 {
            let body = NSLocalizedString(oneKey, tableName: nil, bundle: .main, value: localeCode == "en" ? "There is 1 new article for you." : "Er is 1 nieuw artikel voor je.", comment: "")
            content.body = body
        } else {
            let format = NSLocalizedString(manyKey, tableName: nil, bundle: .main, value: localeCode == "en" ? "There are %d new articles for you." : "Er zijn %d nieuwe artikelen voor je.", comment: "")
            content.body = String(format: format, count)
        }
        content.sound = .default

        return content
    }
}
