import SwiftUI

struct IPadArticlesView: View {
    @AppStorage("pref.lang") private var selectedLanguage: String = "nl"
    @StateObject private var vm = ArticlesViewModel()
    @State private var selectedArticleID: Int?

    private var selectedArticle: Article? {
        vm.articles.first(where: { $0.id == selectedArticleID })
    }

    private var contentTitle: String {
        if let cat = vm.selectedCategory { return cat.name }
        let loc = NSLocalizedString("articles.all", comment: "")
        return loc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Alle artikels" : loc
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

    // MARK: - Sidebar

    private var sidebar: some View {
        List {
            // Alles
            sidebarRow(
                name: NSLocalizedString("articles.all", comment: "").isEmpty ? "Alle artikels" : NSLocalizedString("articles.all", comment: ""),
                color: Brand.blue,
                isSelected: vm.selectedCategory == nil,
                action: showAllCategories
            )

            if !vm.categories.isEmpty {
                Section("Categorieën") {
                    ForEach(vm.categories) { cat in
                        sidebarRow(
                            name: cat.name,
                            color: Brand.categoryColor(for: cat.name),
                            isSelected: vm.selectedCategory?.id == cat.id
                        ) {
                            selectedArticleID = nil
                            vm.selectedCategory = cat
                            Task { await vm.userRefresh() }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(NSLocalizedString("articles.title", comment: "").isEmpty ? "Artikelen" : NSLocalizedString("articles.title", comment: ""))
    }

    private func sidebarRow(name: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color.opacity(0.18))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Circle()
                            .fill(color)
                            .frame(width: 9, height: 9)
                    }

                Text(name)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isSelected
                ? color.opacity(0.10)
                : Color.clear
        )
    }

    // MARK: - Content column

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
        } else if vm.articles.isEmpty {
            ContentUnavailableView(
                "Geen artikels",
                systemImage: "doc.text",
                description: Text("Er zijn geen artikels in deze categorie.")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    // Teller
                    Text("\(vm.articles.count) artikels")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    ForEach(vm.articles) { article in
                        Button {
                            selectedArticleID = article.id
                        } label: {
                            ArticleRow(article: article)
                                .overlay {
                                    if article.id == selectedArticleID {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .strokeBorder(Brand.blue.opacity(0.5), lineWidth: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                    }

                    Spacer().frame(height: 16)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .refreshable { await vm.userRefresh() }
            .navigationTitle(contentTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Detail column

    @ViewBuilder
    private var detailColumn: some View {
        if let article = selectedArticle {
            NavigationStack {
                ArticleDetailView(article: article)
            }
        } else {
            ContentUnavailableView(
                "Selecteer een artikel",
                systemImage: "rectangle.portrait.on.rectangle.portrait",
                description: Text("Kies een artikel uit de lijst.")
            )
        }
    }

    // MARK: - Helpers

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

    private func showAllCategories() {
        selectedArticleID = nil
        vm.selectedCategory = nil
        Task { await vm.userRefresh() }
    }
}
