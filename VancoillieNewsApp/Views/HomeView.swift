import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @StateObject private var vm = ArticlesViewModel()
    @AppStorage("pref.lang") private var selectedLanguage: String = "nl"
    @AppStorage("pref.categories") private var savedCategories: String = ""
    @AppStorage("user.firstname") private var firstName: String = ""

    private var preferredCategoryIDs: Set<Int> {
        Set(savedCategories.split(separator: ",").compactMap { Int($0) })
    }

    private var thisWeekArticles: [Article] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekly = vm.articles.filter { $0.date >= startOfWeek }
        return weekly.isEmpty ? vm.articles : weekly
    }

    private var displayArticles: [Article] {
        let ids = preferredCategoryIDs
        let weekly = thisWeekArticles
        guard !ids.isEmpty else { return weekly }
        let filtered = weekly.filter { ids.contains($0.categoryID) }
        return filtered.isEmpty ? weekly : filtered
    }

    private var topBriefArticles: [Article] {
        Array(thisWeekArticles.prefix(4))
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
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()

                if vm.isLoading && vm.articles.isEmpty {
                    ProgressView().controlSize(.large)
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
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            // Greeting
                            VStack(alignment: .leading, spacing: 4) {
                                Text(firstName.isEmpty ? greeting : "\(greeting) \(firstName)")
                                    .font(.system(size: 28, weight: .bold))
                                Text("\(displayArticles.count) artikels beschikbaar")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                            .padding(.bottom, 16)

                            // Vandaag in het kort
                            if !topBriefArticles.isEmpty {
                                TodayBriefCard(articles: topBriefArticles)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 20)
                            }

                            // Sectieheader
                            SectionHeader(title: NSLocalizedString("home.just_in", comment: ""))
                                .padding(.bottom, 8)

                            // Hero artikel
                            if let hero = displayArticles.first {
                                NavigationLink {
                                    ArticleDetailView(article: hero)
                                } label: {
                                    HeroCardModern(article: hero)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                            }

                            // Overige artikels
                            ForEach(displayArticles.dropFirst()) { article in
                                NavigationLink {
                                    ArticleDetailView(article: article)
                                } label: {
                                    ArticleRowModern(article: article)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 10)
                            }

                            // Meer artikels
                            Button {
                                selectedTab = 1
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Meer artikels bekijken")
                                            .font(.headline)
                                        Text("Inclusief oudere nieuwsberichten")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                        .font(.caption.weight(.semibold))
                                }
                                .padding(16)
                                .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(.primary)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)

                            Spacer().frame(height: 16)
                        }
                    }
                    .refreshable { await vm.userRefresh() }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task(id: selectedLanguage) { await vm.userRefresh() }
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
        .padding(.horizontal, 16)
    }
}

private struct TodayBriefCard: View {
    let articles: [Article]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline)
                Text("Vandaag in het kort")
                    .font(.subheadline.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(articles) { article in
                    NavigationLink {
                        ArticleDetailView(article: article)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Brand.categoryColor(for: article.categoryName))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(article.title)
                                .font(.subheadline)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)

                    if article.id != articles.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        }
    }
}

private struct HeroCardModern: View {
    let article: Article

    private var heroHeight: CGFloat { DeviceLayout.isPad ? 280 : 210 }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArticleImageView(url: article.imageURL)
                .frame(maxWidth: .infinity)
                .frame(height: heroHeight)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            LinearGradient(colors: [.clear, .black.opacity(0.82)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(article.categoryName)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Brand.categoryColor(for: article.categoryName).opacity(0.9), in: Capsule())
                        .foregroundStyle(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(article.readTimeLabel)
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.white)
                }

                Text(article.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.9), radius: 8, y: 2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
    }
}

private struct ArticleRowModern: View {
    let article: Article

    var body: some View {
        HStack(spacing: 12) {
            ArticleImageView(url: article.imageURL)
                .frame(width: 96, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(article.categoryName)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Brand.categoryColor(for: article.categoryName).opacity(0.12), in: Capsule())
                        .foregroundStyle(Brand.categoryColor(for: article.categoryName))
                        .lineLimit(1)

                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(article.readTimeLabel)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05))
        )
    }
}
