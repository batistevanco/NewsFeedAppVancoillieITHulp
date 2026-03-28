//
//  ArticleDetailView.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 11/10/2025.
//


import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let url = article.imageURL {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(.gray.opacity(0.15))
                    }
                    .frame(maxWidth: .infinity, minHeight: DeviceLayout.isPad ? 340 : 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Text(article.title)
                    .font(DeviceLayout.isPad ? .largeTitle.bold() : .title2.bold())

                HStack(spacing: 8) {
                    CategoryBadge(name: article.categoryName)
                    Text(article.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(article.description)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let url = article.fullURL {
                    Button {
                        openURL(url)
                    } label: {
                        HStack {
                            Image(systemName: "safari")
                            Text(NSLocalizedString("article.read_full", comment: ""))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: DeviceLayout.isPad ? 860 : .infinity, alignment: .leading)
            .padding(DeviceLayout.isPad ? 32 : 16)
            .frame(maxWidth: .infinity)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
