//
//  ArticleHeroCard.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 11/10/2025.
//


import SwiftUI

struct ArticleHeroCard: View {
    let article: Article

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = article.imageURL {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    LinearGradient(colors: [.gray.opacity(0.15), .gray.opacity(0.05)],
                                   startPoint: .top, endPoint: .bottom)
                }
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 260)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.gray.opacity(0.12))
                    .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 260)
            }

            // overlay
            LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.65)],
                           startPoint: .center, endPoint: .bottom)
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 260)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    CategoryBadge(name: article.categoryName)
                    Text(article.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Text(article.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(article.title), \(article.categoryName), \(article.date.formatted(date: .abbreviated, time: .omitted))"))
    }
}
