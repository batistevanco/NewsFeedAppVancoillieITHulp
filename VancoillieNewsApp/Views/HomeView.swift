import SwiftUI

struct HomeView: View {
    @StateObject private var vm = ArticlesViewModel()

    private var navTitle: String {
        let t = NSLocalizedString("home.title", comment: "")
        return t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "News" : t
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient background using system colors
                Color(UIColor.systemBackground)
                    .ignoresSafeArea(.container, edges: [.bottom])

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
                                Section(header: SectionHeader(title: NSLocalizedString("home.just_in", comment: ""))) {
                                    NavigationLink {
                                        ArticleDetailView(article: hero)
                                    } label: {
                                        HeroCardModern(article: hero)
                                    }
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                }
                            }

                            // Overige artikels (enkel deze week, zonder beschrijving)
                            let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                            let weekItems = vm.articles.dropFirst().filter { $0.date >= cutoff }
                            if !weekItems.isEmpty {
                                Section(header: SectionHeader(title: NSLocalizedString("home.articles", comment: ""))) {
                                    ForEach(weekItems) { a in
                                        NavigationLink {
                                            ArticleDetailView(article: a)
                                        } label: {
                                            ArticleRowModern(article: a)
                                        }
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .safeAreaInset(edge: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(navTitle)
                                    .font(.largeTitle.weight(.bold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal)
                            .padding(.top, 25)
                            .padding(.bottom, -4)
                            .background(Color(UIColor.systemBackground))
                        }
                        .refreshable { await vm.load() }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task { await vm.load() }
    }
}

// MARK: - Components

private struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color.blue.opacity(0.6)).frame(width: 8, height: 8)
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

private struct HeroCardModern: View {
    let article: Article
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArticleImageView(url: article.imageURL)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            // Gradient overlay for readable text
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(article.categoryName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                Text(article.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .shadow(color: .black.opacity(0.9), radius: 10, y: 3)
            }
            .padding()
        }
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
    }
}

private struct ArticleRowModern: View {
    let article: Article
    var body: some View {
        HStack(spacing: 12) {
            ArticleImageView(url: article.imageURL)
                .frame(width: 92, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(article.categoryName)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            article.categoryName == "Vancoillie IT Hulp"
                                ? Color.blue.opacity(0.15)
                                : Color.red.opacity(0.2),
                            in: Capsule()
                        )
                        .foregroundColor(
                            article.categoryName == "Vancoillie IT Hulp"
                                ? .blue
                                : .gray
                        )
                    Text(article.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15))
        )
    }
}
