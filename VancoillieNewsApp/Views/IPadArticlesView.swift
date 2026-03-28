import SwiftUI

struct IPadArticlesView: View {
    @AppStorage("pref.lang") private var selectedLanguage: String = "nl"
    @StateObject private var vm = ArticlesViewModel()
    @State private var selectedArticleID: Int?

    private var selectedArticle: Article? {
        vm.articles.first(where: { $0.id == selectedArticleID })
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } content: {
            contentColumn
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            await vm.load()
            selectFirstArticleIfNeeded()
        }
        .task(id: selectedLanguage) {
            await vm.languageChangedRefresh()
            syncSelectionAfterReload()
        }
        .onChange(of: vm.articles) { _, _ in
            syncSelectionAfterReload()
        }
    }

    private func selectFirstArticleIfNeeded() {
        if selectedArticleID == nil {
            selectedArticleID = vm.articles.first?.id
        }
    }

    private func syncSelectionAfterReload() {
        if let selectedArticleID, vm.articles.contains(where: { $0.id == selectedArticleID }) {
            return
        }
        self.selectedArticleID = vm.articles.first?.id
    }

    private var sidebar: some View {
        List {
            Section(NSLocalizedString("articles.categories", comment: "")) {
                Button(action: showAllCategories) {
                    Label(NSLocalizedString("articles.all", comment: ""), systemImage: "square.grid.2x2")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tint(vm.selectedCategory == nil ? .accentColor : .primary)

                ForEach(vm.categories) { category in
                    categoryButton(for: category)
                }
            }
        }
        .navigationTitle(NSLocalizedString("articles.categories", comment: ""))
    }

    @ViewBuilder
    private var contentColumn: some View {
        if vm.isLoading && vm.articles.isEmpty {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = vm.error, vm.articles.isEmpty {
            ContentUnavailableView(
                NSLocalizedString("state.load_failed", comment: ""),
                systemImage: "exclamationmark.triangle",
                description: Text(error.localizedDescription)
            )
        } else {
            List(vm.articles) { article in
                articleButton(for: article)
            }
            .navigationTitle(NSLocalizedString("articles.title", comment: ""))
            .refreshable { await vm.userRefresh() }
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let article = selectedArticle {
            NavigationStack {
                ArticleDetailView(article: article)
            }
        } else {
            ContentUnavailableView(
                NSLocalizedString("articles.title", comment: ""),
                systemImage: "rectangle.portrait.on.rectangle.portrait",
                description: Text(NSLocalizedString("state.no_articles_desc", comment: ""))
            )
        }
    }

    private func categoryButton(for category: Category) -> some View {
        Button {
            selectedArticleID = nil
            vm.selectedCategory = category
            Task { await vm.userRefresh() }
        } label: {
            HStack {
                Text(category.name)
                Spacer()
                if vm.selectedCategory?.id == category.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func articleButton(for article: Article) -> some View {
        Button {
            selectedArticleID = article.id
        } label: {
            ArticleRow(article: article)
                .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            article.id == selectedArticleID
                ? Color.accentColor.opacity(0.12)
                : Color.clear
        )
    }

    private func showAllCategories() {
        selectedArticleID = nil
        vm.selectedCategory = nil
        Task { await vm.userRefresh() }
    }
}
