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
    @Published var error: Error?

    private var cancellables = Set<AnyCancellable>()

    // Eén lopende fetch tegelijk
    private var currentTask: Task<Void, Never>? = nil
    private var fetchToken: Int = 0

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

    // MARK: - Public API

    /// Initieel laden (categories + articles)
    func load() async {
        await runFetch(loadCategories: true, forceRefresh: false)
    }

    /// Enkel artikels opnieuw laden (bij pull-to-refresh of categorie wijziging)
    func reloadArticles() async throws {
        // gooi niets door naar boven; we beheren zelf de foutstatus in `error`
        await runFetch(loadCategories: false, forceRefresh: true)
    }

    /// Handig voor .refreshable in Views
    func userRefresh() async {
        await runFetch(loadCategories: false, forceRefresh: true)
    }
    
    func languageChangedRefresh() async {
        await runFetch(loadCategories: true, forceRefresh: true)
    }

    // MARK: - Core fetch

    private func runFetch(loadCategories: Bool, forceRefresh: Bool = false) async {
        // voorkom dubbele loads door vorige task te annuleren
        currentTask?.cancel()
        fetchToken &+= 1
        let token = fetchToken

        isLoading = true
        error = nil

        let task = Task { [weak self] in
            guard let self else { return }
            do {
                if loadCategories {
                    let cats = try await APIClient.shared.fetchCategories(locale: self.lang, forceRefresh: forceRefresh)
                    // selectie stabiel houden
                    if let sel = self.selectedCategory,
                       cats.contains(where: { $0.id == sel.id }) == false {
                        self.selectedCategory = nil
                    }
                    self.categories = cats
                }

                let cid = self.selectedCategory?.id
                let list = try await APIClient.shared.fetchArticles(locale: self.lang, categoryID: cid, forceRefresh: forceRefresh)
                self.articles = list
                self.error = nil
            } catch is CancellationError {
                // genegeerd: er is een nieuwere task gestart
            } catch {
                self.error = error
                self.articles = []
            }
        }

        currentTask = task
        await task.value
        if fetchToken == token {
            currentTask = nil
        }
        isLoading = false
    }
}

// Globale notification key (zichtbaar in heel de module)
extension Notification.Name {
    static let appLanguageChanged = Notification.Name("appLanguageChanged")
}


