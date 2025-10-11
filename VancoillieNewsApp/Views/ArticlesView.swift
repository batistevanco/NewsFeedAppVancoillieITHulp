import SwiftUI

struct ArticlesView: View {
    @StateObject private var vm = ArticlesViewModel()
    // Ensure default selectedCategory is nil so "All" is selected at app startup

    var body: some View {
        NavigationStack {
            List {
                if !vm.categories.isEmpty {
                    Section(NSLocalizedString("articles.categories", comment: "")) {
                        Picker(NSLocalizedString("articles.category_picker", comment: ""),
                               selection: $vm.selectedCategory) {
                            // belangrijk: tags matchen het type van 'selection' (Category?)
                            Text(NSLocalizedString("articles.all", comment: ""))
                                .tag(nil as Category?)

                            ForEach(vm.categories) { c in
                                Text(c.name)
                                    .tag(c as Category?)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .onChange(of: vm.selectedCategory) { _, _ in
                            Task { await vm.reloadArticles() }
                        }
                    }
                }

                Section(NSLocalizedString("articles.list", comment: "")) {
                    ForEach(vm.articles) { a in
                        NavigationLink {
                            ArticleDetailView(article: a)
                        } label: {
                            ArticleRow(article: a)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(NSLocalizedString("articles.title", comment: ""))
        }
        .task { await vm.load() }
        .onAppear {
            vm.selectedCategory = nil
        }
    }
}
