import SwiftUI

struct WatchArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Categorie badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(watchCategoryColor(article.categoryName))
                        .frame(width: 7, height: 7)
                    Text(article.categoryName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(watchCategoryColor(article.categoryName))
                }

                // Titel
                Text(article.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)

                // Datum + leestijd
                HStack(spacing: 8) {
                    Text(article.date, style: .date)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(article.readTimeLabel)
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }

                Divider()

                // Body
                Text(article.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                // Lees volledig
                if let url = article.fullURL {
                    Link(destination: url) {
                        Label("Lees volledig", systemImage: "safari")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle(article.categoryName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
