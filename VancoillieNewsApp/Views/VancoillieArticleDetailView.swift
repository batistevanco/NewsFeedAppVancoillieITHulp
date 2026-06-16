import SwiftUI

struct VancoillieArticleDetailView: View {
    let article: Article
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    private var heroHeight: CGFloat { DeviceLayout.isPad ? 420 : 260 }
    private var contentWidth: CGFloat { DeviceLayout.isPad ? 780 : 640 }
    private var horizontalPadding: CGFloat { DeviceLayout.isPad ? 32 : 18 }

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

            ZStack(alignment: .top) {
                VDetailBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DeviceLayout.isPad ? 28 : 24) {
                        // Datum + titel
                        VStack(spacing: 14) {
                            Text(article.date, format: .dateTime.month(.wide).day().year())
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.82))

                            Text(article.title)
                                .font(DeviceLayout.isPad
                                      ? .system(size: 42, weight: .medium, design: .rounded)
                                      : .system(size: 34, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .minimumScaleFactor(0.78)
                        }
                        .frame(maxWidth: readableWidth)

                        // Categorie + leestijd chips
                        HStack(spacing: 12) {
                            VDetailChip(text: article.categoryName)
                            VDetailChip(text: "\(article.readTime) min")
                        }

                        // Afbeelding
                        ArticleImageView(url: article.imageURL)
                            .frame(width: readableWidth, height: heroHeight)
                            .clipShape(RoundedRectangle(cornerRadius: DeviceLayout.isPad ? 32 : 28, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DeviceLayout.isPad ? 32 : 28, style: .continuous)
                                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.20), radius: 24, y: 16)

                        // Tekst
                        VStack(alignment: .leading, spacing: 22) {
                            if let leadSentence {
                                Text(leadSentence)
                                    .font(introFont)
                                    .foregroundStyle(.white)
                                    .lineSpacing(7)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            VDetailWatJeMoetweten(article: article)

                            if let remainingBody {
                                Text(remainingBody)
                                    .font(bodyFont)
                                    .foregroundStyle(.white)
                                    .lineSpacing(8)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(width: readableWidth, alignment: .leading)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 112)
                    .frame(maxWidth: .infinity)
                }

                // Topbar: terug + lees volledig
                VDetailTopBar(
                    onBack: { dismiss() },
                    readFullAction: article.fullURL == nil ? nil : {
                        if let url = article.fullURL { openURL(url) }
                    }
                )
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 18)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Chrome

private struct VDetailTopBar: View {
    let onBack: () -> Void
    let readFullAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 46, height: 46)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.24), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)

            Spacer()

            if let readFullAction {
                Button(action: readFullAction) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari")
                            .font(.system(size: 15, weight: .semibold))
                        Text(NSLocalizedString("article.read_full", comment: ""))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 46)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.28), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct VDetailChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 18)
            .frame(height: 40)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.28), lineWidth: 1))
    }
}

// MARK: - Wat je moet weten (donkere stijl)

private struct VDetailWatJeMoetweten: View {
    let article: Article

    private var bullets: [String] {
        let trimmed = article.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        var sentences: [String] = []
        var current = ""
        for char in trimmed {
            current.append(char)
            if ".!?".contains(char) {
                let s = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if s.count > 20 { sentences.append(s) }
                current = ""
                if sentences.count >= 3 { break }
            }
        }
        return sentences
    }

    var body: some View {
        let items = bullets
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Wat je moet weten")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.0) { _, bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(.white)
                                .frame(width: 6, height: 6)
                                .padding(.top, 9)
                            Text(bullet)
                                .font(.system(size: 17, weight: .regular, design: .rounded))
                                .foregroundStyle(.white)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Aurora achtergrond (detail)

private struct VDetailBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "081143"), Color(hex: "130033"), Color(hex: "00366F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            AngularGradient(
                colors: [
                    Color(hex: "263AFF").opacity(0.92),
                    Color(hex: "EA79D2").opacity(0.82),
                    Color(hex: "8EDCFF").opacity(0.90),
                    Color(hex: "1747A5").opacity(0.84),
                    Color(hex: "263AFF").opacity(0.92)
                ],
                center: .center
            )
            .blur(radius: 54)
            .scaleEffect(1.42)
            LinearGradient(
                colors: [.black.opacity(0.10), .white.opacity(0.07), .black.opacity(0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
