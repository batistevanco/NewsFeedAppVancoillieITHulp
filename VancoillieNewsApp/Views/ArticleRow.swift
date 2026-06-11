import SwiftUI

struct ArticleRow: View {
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
                        Image(systemName: "clock").font(.caption2)
                        Text(article.readTimeLabel).font(.caption2)
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
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
