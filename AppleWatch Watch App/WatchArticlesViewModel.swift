import Foundation
internal import Combine

@MainActor
final class WatchArticlesViewModel: ObservableObject {

    @Published var articlesThisWeek: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(forceRefresh: Bool = true) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let lang = LocaleHelper.appLangParam

            // LET OP: forceRefresh staat hier standaard op true
            let all = try await APIClient.shared.fetchArticles(
                locale: lang,
                categoryID: nil,
                forceRefresh: forceRefresh
            )

            // jouw filter van daarnet (laatste 7 dagen)
            let filtered = Self.filterLast7Days(all)
            self.articlesThisWeek = filtered.sorted { $0.date > $1.date }

        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private static func filterLast7Days(_ articles: [Article]) -> [Article] {
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        return articles.filter { $0.date >= sevenDaysAgo && $0.date <= now }
    }
}
