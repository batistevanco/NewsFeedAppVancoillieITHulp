//
//  ArticleImageView.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 11/10/2025.
//


import SwiftUI

struct ArticleImageView: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                // Gebruik de standaard AsyncImage(url:) initializer; caching wordt geregeld via URLCache
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Rectangle().fill(.secondary.opacity(0.1))
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .transition(.opacity)
                    case .failure:
                        ZStack {
                            Rectangle().fill(.secondary.opacity(0.1))
                            Image(systemName: "photo")
                                .imageScale(.large)
                                .foregroundStyle(.secondary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipped()
            } else {
                ZStack {
                    Rectangle().fill(.secondary.opacity(0.1))
                    Image(systemName: "photo")
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
