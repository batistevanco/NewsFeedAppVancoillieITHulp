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

    private var heroHeight: CGFloat {
        DeviceLayout.isPad ? 420 : 260
    }

    private var contentWidth: CGFloat {
        DeviceLayout.isPad ? 780 : 640
    }

    private var titleFont: Font {
        DeviceLayout.isPad
            ? .system(size: 40, weight: .bold, design: .serif)
            : .system(size: 32, weight: .bold, design: .serif)
    }

    private var introFont: Font {
        DeviceLayout.isPad
            ? .system(size: 24, weight: .medium, design: .serif)
            : .system(size: 21, weight: .medium, design: .serif)
    }

    private var bodyFont: Font {
        DeviceLayout.isPad
            ? .system(size: 19, weight: .regular, design: .serif)
            : .system(size: 18, weight: .regular, design: .serif)
    }

    private var horizontalPadding: CGFloat {
        DeviceLayout.isPad ? 32 : 18
    }

    private var leadSentence: String? {
        let trimmed = article.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let terminators = CharacterSet(charactersIn: ".!?")
        if let range = trimmed.rangeOfCharacter(from: terminators) {
            let sentence = String(trimmed[..<range.upperBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            return sentence.isEmpty ? nil : sentence
        }

        return trimmed
    }

    private var remainingBody: String? {
        let trimmed = article.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let leadSentence, trimmed.count > leadSentence.count else { return nil }

        let start = trimmed.index(trimmed.startIndex, offsetBy: leadSentence.count)
        let remainder = trimmed[start...].trimmingCharacters(in: .whitespacesAndNewlines)
        return remainder.isEmpty ? nil : remainder
    }

    var body: some View {
        GeometryReader { proxy in
            let readableWidth = min(
                max(proxy.size.width - (horizontalPadding * 2), 0),
                contentWidth
            )

            ScrollView {
                VStack(alignment: .leading, spacing: DeviceLayout.isPad ? 28 : 22) {
                    if let url = article.imageURL {
                        AsyncImage(url: url) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(.gray.opacity(0.15))
                        }
                        .frame(width: readableWidth, height: heroHeight)
                        .clipShape(RoundedRectangle(cornerRadius: DeviceLayout.isPad ? 32 : 24, style: .continuous))
                        .overlay(alignment: .bottomLeading) {
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DeviceLayout.isPad ? 32 : 24, style: .continuous))
                        }
                        .shadow(color: .black.opacity(0.18), radius: 18, y: 12)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text(article.title)
                            .font(titleFont)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(width: readableWidth, alignment: .leading)

                        HStack(spacing: 10) {
                            CategoryBadge(name: article.categoryName)

                            Text(article.date, style: .date)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, DeviceLayout.isPad ? 4 : 0)

                    VStack(alignment: .leading, spacing: DeviceLayout.isPad ? 22 : 18) {
                        if let leadSentence {
                            Text(leadSentence)
                                .font(introFont)
                                .foregroundStyle(.primary.opacity(0.9))
                                .lineSpacing(DeviceLayout.isPad ? 10 : 8)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let remainingBody {
                            Divider()
                                .overlay(Color.primary.opacity(0.08))

                            Text(remainingBody)
                                .font(bodyFont)
                                .foregroundStyle(.primary.opacity(0.84))
                                .lineSpacing(DeviceLayout.isPad ? 11 : 9)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(DeviceLayout.isPad ? 30 : 22)
                    .frame(width: readableWidth, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(UIColor.secondarySystemBackground),
                                Color(UIColor.systemBackground)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: DeviceLayout.isPad ? 30 : 24, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: DeviceLayout.isPad ? 30 : 24, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.06))
                    }
                    .shadow(color: .black.opacity(0.06), radius: 16, y: 10)
                    
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
                        .controlSize(DeviceLayout.isPad ? .large : .regular)
                        .padding(.top, 4)
                    }
                }
                .frame(width: readableWidth, alignment: .leading)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, DeviceLayout.isPad ? 28 : 20)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
