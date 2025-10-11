import SwiftUI

struct HomeView: View {
    @StateObject private var vm = ArticlesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                } else if vm.articles.isEmpty {
                    ContentUnavailableView(
                        NSLocalizedString("state.no_articles", comment: ""),
                        systemImage: "doc.text.image",
                        description: Text(NSLocalizedString("state.no_articles_desc", comment: ""))
                    )
                } else {
                    List {
                        // Hero
                        if let hero = vm.articles.first {
                            Section(NSLocalizedString("home.just_in", comment: "")) {
                                NavigationLink {
                                    ArticleDetailView(article: hero)
                                } label: {
                                    ArticleHeroCard(article: hero)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                            }
                        }

                        // Overige artikels (enkel deze week, zonder beschrijving)
                        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                        let weekItems = vm.articles.dropFirst().filter { $0.date >= cutoff }
                        if !weekItems.isEmpty {
                            Section(NSLocalizedString("home.articles", comment: "")) {
                                ForEach(weekItems) { a in
                                    NavigationLink {
                                        ArticleDetailView(article: a)
                                    } label: {
                                        ArticleRow(article: a)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await vm.load() }
                }
            }
            .navigationTitle(NSLocalizedString("home.title", comment: ""))
        }
        .task { await vm.load() }
    }
}
