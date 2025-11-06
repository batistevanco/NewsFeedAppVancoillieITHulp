import Foundation
import Combine

@MainActor
final class WatchArticlesViewModel: ObservableObject {

    @Published var articlesThisWeek: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let lang = LocaleHelper.appLangParam
            let all = try await APIClient.shared.fetchArticles(
                locale: lang,
                categoryID: nil,
                forceRefresh: false
            )

            // i.p.v. calendar week: laatste 7 dagen
            let filtered = Self.filterLast7Days(all)
            self.articlesThisWeek = filtered.sorted { $0.date > $1.date }

        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private static func filterLast7Days(_ articles: [Article]) -> [Article] {
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        return articles.filter { article in
            article.date >= sevenDaysAgo && article.date <= now
        }
    }
}
