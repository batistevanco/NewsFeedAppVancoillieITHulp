import Foundation
import SwiftUI
internal import Combine

@MainActor
final class ArticlesViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var categories: [Category] = []
    @Published var error: String?
    @Published var isLoading: Bool = false
    @Published var selectedCategory: Category? = nil  // nil = Alle/All

    private let locale = "nl"

    func load() async {
        isLoading = true
        // 1) Toon meteen cache
        if let cached = ArticleCache.load(lang: locale, categoryID: selectedCategory?.id), !cached.isEmpty {
            self.articles = cached
        }
        // 2) Haal netwerkversie (stille refresh)
        await reloadArticles()
        isLoading = false
    }

    func reloadArticles() async {
        do {
            let fresh = try await APIClient.shared.fetchArticles(locale: locale, categoryID: selectedCategory?.id)
            self.articles = fresh
            self.error = nil
            ArticleCache.save(fresh, lang: locale, categoryID: selectedCategory?.id)
        } catch {
            // Bij fout lijst niet leegmaken
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
