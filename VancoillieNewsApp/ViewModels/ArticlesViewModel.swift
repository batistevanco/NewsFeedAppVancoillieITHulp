import Foundation
import SwiftUI
import Combine

@MainActor
final class ArticlesViewModel: ObservableObject {

    // Persisted language (default NL)
    @AppStorage("app.language") private var languageRaw: String = "nl"

    // Data
    @Published var categories: [Category] = []
    @Published var articles: [Article] = []
    @Published var selectedCategory: Category? = nil
    @Published var isLoading = false
    @Published var error: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Als gebruiker taal wijzigt in Settings → onmiddellijk herladen
        NotificationCenter.default.publisher(for: .appLanguageChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { await self?.load() }
            }
            .store(in: &cancellables)
    }

    // Huidige taalcode (alleen "nl" of "en" doorgeven)
    private var lang: String {
        languageRaw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "en" ? "en" : "nl"
    }

    // Initieel laden (categories + articles)
    func load() async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let cats = try await APIClient.shared.fetchCategories(locale: lang)
            categories = cats

            // Houd selectie stabiel, zo niet -> reset naar Alle
            if let sel = selectedCategory,
               cats.contains(where: { $0.id == sel.id }) == false {
                selectedCategory = nil
            }

            try await reloadArticles()
        } catch {
            self.error = error.localizedDescription
            self.articles = []
        }
    }

    // Enkel artikels opnieuw laden (bij pull-to-refresh of categorie wijziging)
    func reloadArticles() async throws {
        error = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let cid = selectedCategory?.id
            let list = try await APIClient.shared.fetchArticles(locale: lang, categoryID: cid)
            self.articles = list
        } catch {
            self.error = error.localizedDescription
            self.articles = []
            throw error
        }
    }

    // Handig voor .refreshable in Views
    func userRefresh() async {
        do {
            try await reloadArticles()
        } catch { /* error reeds gezet */ }
    }
}

// Globale notification key (zichtbaar in heel de module)
extension Notification.Name {
    static let appLanguageChanged = Notification.Name("appLanguageChanged")
}
