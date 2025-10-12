import SwiftUI

private enum UI {
    static let corner: CGFloat = 14
    static let rowSpacing: CGFloat = 8
}

struct ArticlesView: View {
    @AppStorage("pref.lang") private var selectedLanguage: String = "nl"
    @StateObject private var vm = ArticlesViewModel()  

    private var navTitle: String {
        let t = NSLocalizedString("articles.title", comment: "")
        return t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Artikelen" : t
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()

                if vm.isLoading && vm.articles.isEmpty {
                    ProgressView()
                        .scaleEffect(2)
                } else if let error = vm.error, vm.articles.isEmpty {
                    ContentUnavailableView(
                        "Kan niet laden",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error.localizedDescription)
                    )
                } else {
                    List {
                        // Categorieën
                        if !vm.categories.isEmpty {
                            Section(header: SectionHeader(title: NSLocalizedString("articles.categories", comment: ""))) {
                                Picker(NSLocalizedString("articles.category_picker", comment: ""), selection: $vm.selectedCategory) {
                                    Text(NSLocalizedString("articles.all", comment: ""))
                                        .tag(nil as Category?)
                                    ForEach(vm.categories) { c in
                                        Text(c.name).tag(c as Category?)
                                    }
                                }
                                .pickerStyle(.navigationLink)
                            }
                        }

                        // Artikellijst
                        Section(header: SectionHeader(title: NSLocalizedString("articles.list", comment: ""))) {
                            ForEach(vm.articles) { a in
                                NavigationLink {
                                    ArticleDetailView(article: a)
                                } label: {
                                    ArticleRowModern(article: a)
                                }
                                .buttonStyle(.plain)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.vertical, UI.rowSpacing)
                    .refreshable { await vm.load() }
                }
            }
            // Grote custom titel zoals in HomeView
            .safeAreaInset(edge: .top) {
                HStack { // left aligned
                    Text(navTitle)
                        .font(.largeTitle.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 25)
                        .padding(.bottom, -4)
                }
                .background(Color(UIColor.systemBackground))
            }
        }
        .task { await vm.load() }
        .task(id: selectedLanguage) { await vm.userRefresh() }
        .task(id: vm.selectedCategory?.id) { await vm.userRefresh() }
        .onAppear { vm.selectedCategory = vm.selectedCategory } // keep selection, ensure state
    }
}

// MARK: - Components (matching HomeView)

private struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color.blue.opacity(0.7)).frame(width: 8, height: 8)
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

private struct ArticleRowModern: View {
    let article: Article
    var body: some View {
        HStack(spacing: 12) {
            ArticleImageView(url: article.imageURL)
                .frame(width: 92, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: UI.corner, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(article.categoryName)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            article.categoryName == "Vancoillie IT Hulp"
                                ? Color.blue.opacity(0.15)
                                : Color.red.opacity(0.15),
                            in: Capsule()
                        )
                        .foregroundColor(
                            article.categoryName == "Vancoillie IT Hulp"
                                ? .blue
                                : .gray
                        )
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .minimumScaleFactor(0.9)
                        .layoutPriority(1)
                    Text(article.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: UI.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: UI.corner, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15))
        )
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 4)
    }
}
