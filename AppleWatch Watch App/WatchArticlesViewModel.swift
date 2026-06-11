import Foundation
import SwiftUI
internal import Combine

func watchCategoryColor(_ name: String) -> Color {
    let lower = name.lowercased()
    if lower.contains("vancoillie")                          { return .blue }
    if lower.contains("tech") || lower.contains("technolog") { return .blue }
    if lower.contains("sport")                               { return .green }
    if lower.contains("financ") || lower.contains("econom") { return .yellow }
    if lower.contains(" ai") || lower.contains("artifici")  { return .purple }
    if lower.contains("belgi")                               { return .red }
    if lower.contains("gaming") || lower.contains("game")   { return .indigo }
    return .gray
}

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
