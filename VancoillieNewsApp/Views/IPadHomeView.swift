import SwiftUI

struct IPadHomeView: View {
    @Binding var selectedTab: Int
    @StateObject private var vm = ArticlesViewModel()
    @AppStorage("pref.lang") private var selectedLanguage: String = "nl"
    @AppStorage("pref.categories") private var savedCategories: String = ""
    @AppStorage("user.firstname") private var firstName: String = ""

    private let homeArticleLimit = 6

    private var navTitle: String {
        let title = NSLocalizedString("home.title", comment: "")
        return title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "News" : title
    }

    private var preferredCategoryIDs: Set<Int> {
        Set(savedCategories.split(separator: ",").compactMap { Int($0) })
    }

    private var displayArticles: [Article] {
        let ids = preferredCategoryIDs
        guard !ids.isEmpty else { return vm.articles }
        let filtered = vm.articles.filter { ids.contains($0.categoryID) }
        return filtered.isEmpty ? vm.articles : filtered
    }

    private var recentArticles: [Article] {
        Array(displayArticles.dropFirst().prefix(homeArticleLimit))
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Goedemorgen"
        case 12..<18: return "Goedemiddag"
        default:     return "Goedenavond"
        }
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
                                // Greeting + brief card
                                VStack(alignment: .leading, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(firstName.isEmpty ? greeting : "\(greeting) \(firstName)")
                                            .font(.system(size: 32, weight: .bold))
                                        Text("\(displayArticles.count) artikels beschikbaar")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    let briefArticles = Array(vm.articles.prefix(4))
                                    if !briefArticles.isEmpty {
                                        IPadTodayBriefCard(articles: briefArticles)
                                    }
                                }

                                if let hero = displayArticles.first {
                                    NavigationLink {
                                        ArticleDetailView(article: hero)
                                    } label: {
                                        IPadHeroCard(article: hero)
                                    }
                                    .buttonStyle(.plain)
                                }

                                if !recentArticles.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Laatste nieuws")
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

                                        Button {
                                            selectedTab = 1
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Meer artikels bekijken")
                                                        .font(.headline)
                                                    Text("Inclusief oudere nieuwsberichten")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundStyle(.secondary)
                                                    .font(.subheadline.weight(.semibold))
                                            }
                                            .padding(20)
                                            .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                            .foregroundStyle(.primary)
                                        }
                                        .buttonStyle(.plain)
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

private struct IPadTodayBriefCard: View {
    let articles: [Article]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.orange)
                Text("Vandaag in het kort")
                    .font(.subheadline.weight(.semibold))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(articles) { article in
                    NavigationLink {
                        ArticleDetailView(article: article)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Brand.categoryColor(for: article.categoryName))
                                .frame(width: 6, height: 6)
                                .padding(.top, 5)
                            Text(article.title)
                                .font(.subheadline)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        }
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

                    HStack(spacing: 3) {
                        Image(systemName: "clock").font(.caption2)
                        Text(article.readTimeLabel).font(.caption)
                    }
                    .foregroundStyle(.secondary)
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
