//
//  WatchArticleDetailView.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 06/11/2025.
//


import SwiftUI

struct WatchArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {

                Text(article.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(article.categoryName)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // als je artikel een datum heeft die mooi is:
                if let formattedDate = formatDate(article.date) {
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // beschrijving / body
                Text(article.description)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)

                // als je API een fullURL meegeeft
                if let url = article.fullURL {
                    Link("Lees volledig", destination: url)
                        .font(.caption2)
                        .padding(.top, 6)
                }
            }
            .padding(.vertical, 6)
        }
        .containerBackground(Color(red: 0.1, green: 0.12, blue: 0.15), for: .navigation)
        .navigationTitle("Artikel")
    }

    private func formatDate(_ date: Date) -> String? {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}