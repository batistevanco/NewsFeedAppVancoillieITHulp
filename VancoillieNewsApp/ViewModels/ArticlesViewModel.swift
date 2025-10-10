//
//  ArticlesViewModel.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 10/10/2025.
//


import Foundation
internal import Combine

@MainActor
final class ArticlesViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var error: String?

    func load() async {
        isLoading = true; defer { isLoading = false }
        do {
            let lang = LocaleHelper.appLangParam
            categories = try await APIClient.shared.fetchCategories(locale: lang)
            if selectedCategory == nil { selectedCategory = categories.first }
            try await reloadArticles()
        } catch { self.error = error.localizedDescription }
    }

    func reloadArticles() async throws {
        let lang = LocaleHelper.appLangParam
        let catID = selectedCategory?.id
        articles = try await APIClient.shared.fetchArticles(locale: lang, categoryID: catID)
    }
}
