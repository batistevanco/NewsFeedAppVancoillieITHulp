import SwiftUI

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
                    ProgressView().controlSize(.large)
                } else if let error = vm.error, vm.articles.isEmpty {
                    ContentUnavailableView(
                        "Kan niet laden",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error.localizedDescription)
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            // Artikel-teller
                            Text(vm.articles.isEmpty ? "Geen artikels" : "\(vm.articles.count) artikels")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.top, 4)
                                .padding(.bottom, 14)

                            // Artikel-rijen
                            ForEach(vm.articles) { article in
                                NavigationLink {
                                    ArticleDetailView(article: article)
                                } label: {
                                    ArticleCard(article: article)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                            }

                            Spacer().frame(height: 16)
                        }
                    }
                    .refreshable { await vm.userRefresh() }
                    .animation(.default, value: vm.articles.count)
                }
            }
            .safeAreaInset(edge: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(navTitle)
                        .font(.largeTitle.weight(.bold))
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                    // Categorie-chips
                    if !vm.categories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                CategoryChip(
                                    name: NSLocalizedString("articles.all", comment: "").isEmpty ? "Alles" : NSLocalizedString("articles.all", comment: ""),
                                    isSelected: vm.selectedCategory == nil,
                                    color: Brand.blue
                                ) {
                                    if vm.selectedCategory != nil {
                                        vm.selectedCategory = nil
                                        Task { await vm.userRefresh() }
                                    }
                                }
                                ForEach(vm.categories) { cat in
                                    CategoryChip(
                                        name: cat.name,
                                        isSelected: vm.selectedCategory?.id == cat.id,
                                        color: Brand.categoryColor(for: cat.name)
                                    ) {
                                        if vm.selectedCategory?.id != cat.id {
                                            vm.selectedCategory = cat
                                            Task { await vm.userRefresh() }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 2)
                        }
                    } else if vm.isLoading {
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .frame(width: 72, height: 34)
                            }
                        }
                        .padding(.horizontal, 16)
                        .redacted(reason: .placeholder)
                    }

                    Divider().padding(.horizontal, 16)
                }
                .background(Color(UIColor.systemBackground))
            }
        }
        .task { await vm.load() }
        .task(id: selectedLanguage) { await vm.languageChangedRefresh() }
    }
}

// MARK: - CategoryChip

private struct CategoryChip: View {
    let name: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? color : Color(UIColor.secondarySystemBackground),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - ArticleCard

private struct ArticleCard: View {
    let article: Article

    var body: some View {
        HStack(spacing: 14) {
            ArticleImageView(url: article.imageURL)
                .frame(width: 100, height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(article.categoryName)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Brand.categoryColor(for: article.categoryName).opacity(0.12), in: Capsule())
                        .foregroundStyle(Brand.categoryColor(for: article.categoryName))
                        .lineLimit(1)

                    Text(article.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Spacer(minLength: 0)

                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(article.readTimeLabel)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.04))
        }
    }
}
