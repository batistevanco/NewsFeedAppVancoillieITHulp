import SwiftUI

struct IPadHomeView: View {
    @StateObject private var vm = ArticlesViewModel()
    @AppStorage("pref.lang") private var selectedLanguage: String = "nl"

    private var navTitle: String {
        let title = NSLocalizedString("home.title", comment: "")
        return title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "News" : title
    }

    private var recentArticles: [Article] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return vm.articles.dropFirst().filter { $0.date >= cutoff }
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.articles.isEmpty {
                    ProgressView()
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = vm.error, vm.articles.isEmpty {
                    ContentUnavailableView(
                        NSLocalizedString("state.load_failed", comment: ""),
                        systemImage: "exclamationmark.triangle",
                        description: Text(err.localizedDescription)
                    )
                } else if vm.articles.isEmpty {
                    ContentUnavailableView(
                        NSLocalizedString("state.no_articles", comment: ""),
                        systemImage: "doc.text.image",
                        description: Text(NSLocalizedString("state.no_articles_desc", comment: ""))
                    )
                } else {
                    GeometryReader { proxy in
                        let isPortrait = proxy.size.height > proxy.size.width
                        let gridColumns = Array(
                            repeating: GridItem(.flexible(), spacing: 20, alignment: .top),
                            count: isPortrait ? 1 : 2
                        )

                        ScrollView {
                            VStack(alignment: .leading, spacing: 28) {
                                if let hero = vm.articles.first {
                                    NavigationLink {
                                        ArticleDetailView(article: hero)
                                    } label: {
                                        IPadHeroCard(article: hero)
                                    }
                                    .buttonStyle(.plain)
                                }

                                if !recentArticles.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text(NSLocalizedString("home.articles", comment: ""))
                                            .font(.title2.weight(.bold))

                                        LazyVGrid(columns: gridColumns, spacing: 20) {
                                            ForEach(recentArticles) { article in
                                                NavigationLink {
                                                    ArticleDetailView(article: article)
                                                } label: {
                                                    IPadArticleCard(article: article)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: 1100)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 24)
                        }
                    }
                    .refreshable { await vm.userRefresh() }
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.large)
        }
        .task(id: selectedLanguage) { await vm.userRefresh() }
    }
}

private struct IPadHeroCard: View {
    let article: Article

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArticleImageView(url: article.imageURL)
                .frame(height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            LinearGradient(
                colors: [.clear, .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                CategoryBadge(name: article.categoryName)

                Text(article.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(3)

                Text(article.description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3)
            }
            .padding(28)
        }
        .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
    }
}

private struct IPadArticleCard: View {
    let article: Article

    private let cardHeight: CGFloat = 430

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ArticleImageView(url: article.imageURL)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .frame(height: 102, alignment: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    CategoryBadge(name: article.categoryName)

                    Text(article.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(article.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .frame(height: 72, alignment: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14))
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 14, y: 8)
    }
}
