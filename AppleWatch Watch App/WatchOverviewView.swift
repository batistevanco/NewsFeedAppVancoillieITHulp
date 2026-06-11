import SwiftUI

struct WatchOverviewView: View {
    @EnvironmentObject var vm: WatchArticlesViewModel

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.articlesThisWeek.isEmpty {
                    ProgressView("Laden…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let msg = vm.errorMessage, vm.articlesThisWeek.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                        Text("Kon niet laden")
                            .font(.headline)
                        Button("Opnieuw") {
                            Task { await vm.load(forceRefresh: true) }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.articlesThisWeek.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "newspaper")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Geen artikels\ndeze week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.articlesThisWeek) { article in
                            NavigationLink {
                                WatchArticleDetailView(article: article)
                            } label: {
                                WatchArticleRow(article: article)
                            }
                        }
                    }
                    .refreshable {
                        await vm.load(forceRefresh: true)
                    }
                }
            }
            .navigationTitle("Nieuws")
        }
        .task {
            await vm.load(forceRefresh: true)
        }
    }
}

private struct WatchArticleRow: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(watchCategoryColor(article.categoryName))
                    .frame(width: 7, height: 7)
                Text(article.categoryName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(watchCategoryColor(article.categoryName))
                    .lineLimit(1)
            }

            Text(article.title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(3)
                .foregroundStyle(.primary)

            Text(article.date, style: .relative)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
