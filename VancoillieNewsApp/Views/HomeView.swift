//
//  HomeView.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 10/10/2025.
//


import SwiftUI

struct HomeView: View {
    @StateObject private var vm = ArticlesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                } else if !vm.articles.isEmpty {
                    List {
                        Section(NSLocalizedString("home.just_in", comment: "")) {
                            ForEach(vm.articles.prefix(1)) { a in
                                ArticleRow(article: a, isHero: true)
                            }
                        }
                        Section(NSLocalizedString("home.articles", comment: "")) {
                            ForEach(vm.articles) { a in
                                ArticleRow(article: a)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    ContentUnavailableView(NSLocalizedString("state.no_articles", comment: ""),
                                           systemImage: "doc.text.image",
                                           description: Text(NSLocalizedString("state.no_articles_desc", comment: "")))
                }
            }
            .navigationTitle(NSLocalizedString("home.title", comment: ""))
        }
        .task { await vm.load() }
    }
}

struct ArticleRow: View {
    let article: Article
    var isHero = false

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: article.imageURL) { img in
                img.resizable().scaledToFill()
            } placeholder: { Color.gray.opacity(0.2) }
            .frame(width: isHero ? 88 : 56, height: isHero ? 88 : 56)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(article.title).fontWeight(.semibold)
                Text(article.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                Text(article.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}