import SwiftUI

struct ArticleRow: View {
    let article: Article

    var body: some View {
        HStack(spacing: 12) {
            ArticleImageView(url: article.imageURL)
                .frame(width: 92, height: 68)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    CategoryBadge(name: article.categoryName)
                    Text(article.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}
