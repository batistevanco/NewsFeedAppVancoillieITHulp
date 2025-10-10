//
//  ArticlesView.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 10/10/2025.
//


import SwiftUI

struct ArticlesView: View {
    @StateObject private var vm = ArticlesViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !vm.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(vm.categories) { cat in
                                Button {
                                    vm.selectedCategory = cat
                                    Task { try? await vm.reloadArticles() }
                                } label: {
                                    Text(cat.name)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(vm.selectedCategory == cat ? Brand.blue.opacity(0.15) : Color.gray.opacity(0.12))
                                        .foregroundColor(vm.selectedCategory == cat ? Brand.blue : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }.padding(.horizontal).padding(.vertical, 8)
                    }
                }

                List(vm.articles) { a in
                    ArticleRow(article: a)
                }
                .listStyle(.plain)
                .overlay {
                    if vm.isLoading { ProgressView() }
                }
                .refreshable {
                    try? await vm.reloadArticles()
                }
            }
            .navigationTitle(NSLocalizedString("articles.title", comment: ""))
            .task { await vm.load() }
        }
    }
}