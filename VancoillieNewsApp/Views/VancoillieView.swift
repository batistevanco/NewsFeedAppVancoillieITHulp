import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
final class VancoillieViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var error: Error?

    private var currentTask: Task<Void, Never>?

    private var lang: String {
        let raw = UserDefaults.standard.string(forKey: "app.language") ?? "nl"
        return raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "en" ? "en" : "nl"
    }

    func load(forceRefresh: Bool = false) async {
        currentTask?.cancel()
        isLoading = true
        error = nil
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                async let a = APIClient.shared.fetchArticles(locale: lang, categoryID: 8, forceRefresh: forceRefresh)
                async let b = APIClient.shared.fetchArticles(locale: lang, categoryID: 15, forceRefresh: forceRefresh)
                let merged = try await (a + b).sorted { $0.date > $1.date }
                self.articles = merged
                self.error = nil
            } catch is CancellationError {
            } catch {
                self.error = error
                self.articles = []
            }
        }
        currentTask = task
        await task.value
        isLoading = false
    }
}

// MARK: - VancoillieView

struct VancoillieView: View {
    @Binding var selectedTab: Int
    @AppStorage("pref.lang") private var selectedLanguage: String = "nl"
    @StateObject private var vm = VancoillieViewModel()
    @State private var heroIndex = 0
    private let carouselTimer = Timer.publish(every: 4.5, on: .main, in: .common).autoconnect()

    private var heroArticles: [Article] { Array(vm.articles.prefix(5)) }
    private var listArticles: [Article]  { Array(vm.articles.dropFirst(5)) }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                TrendBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("Nieuws van\nVancoillie")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                            .padding(.top, 18)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if vm.isLoading && vm.articles.isEmpty {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 80)
                        } else if let err = vm.error, vm.articles.isEmpty {
                            GlassErrorView(message: err.localizedDescription)
                        } else if !heroArticles.isEmpty {
                            HeroStackPager(articles: heroArticles, heroIndex: $heroIndex)
                        }

                        if !listArticles.isEmpty {
                            HStack {
                                Text("Artikelen")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Spacer()
                                Button("Zie alles") {
                                    selectedTab = 1
                                }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.78))
                            }
                            .padding(.top, -4)

                            VStack(spacing: 14) {
                                ForEach(listArticles) { article in
                                    NavigationLink {
                                        VancoillieArticleDetailView(article: article)
                                    } label: {
                                        GlassNewsArticleRow(article: article)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Spacer().frame(height: 86)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 16)
                }
                .refreshable { await vm.load(forceRefresh: true) }
            }
            .navigationBarHidden(true)
        }
        .task { await vm.load() }
        .task(id: selectedLanguage) { await vm.load(forceRefresh: true) }
        .onReceive(carouselTimer) { _ in
            guard heroArticles.count > 1 else { return }
            withAnimation(.easeInOut(duration: 0.45)) {
                heroIndex = (heroIndex + 1) % heroArticles.count
            }
        }
        .onChange(of: heroArticles.count) { _, count in
            guard count > 0, heroIndex >= count else { return }
            heroIndex = 0
        }
    }
}

// MARK: - TrendBackground

private struct TrendBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "081143"), Color(hex: "120032"), Color(hex: "012B67")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            AngularGradient(
                colors: [
                    Color(hex: "243CFF").opacity(0.9),
                    Color(hex: "F67AD8").opacity(0.76),
                    Color(hex: "81D9FF").opacity(0.82),
                    Color(hex: "162C87").opacity(0.86),
                    Color(hex: "243CFF").opacity(0.9)
                ],
                center: animate ? .init(x: 0.64, y: 0.56) : .init(x: 0.42, y: 0.48)
            )
            .blur(radius: 48)
            .scaleEffect(1.35)
            .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)

            LinearGradient(
                colors: [.black.opacity(0.16), .white.opacity(0.08), .black.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
    }
}

// MARK: - HeroStackPager

private struct HeroStackPager: View {
    let articles: [Article]
    @Binding var heroIndex: Int

    private let heroHeight: CGFloat = DeviceLayout.isPad ? 280 : 230

    var body: some View {
        VStack(spacing: 12) {
            TabView(selection: $heroIndex) {
                ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                    NavigationLink {
                        VancoillieArticleDetailView(article: article)
                    } label: {
                        HeroCard(article: article, height: heroHeight)
                    }
                    .buttonStyle(.plain)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: heroHeight)

            HStack(spacing: 6) {
                ForEach(0..<articles.count, id: \.self) { index in
                    Circle()
                        .fill(index == heroIndex ? .white : .white.opacity(0.48))
                        .frame(width: index == heroIndex ? 11 : 9, height: index == heroIndex ? 11 : 9)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)
        }
    }
}

// MARK: - HeroCard

private struct HeroCard: View {
    let article: Article
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArticleImageView(url: article.imageURL)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            LinearGradient(colors: [.clear, .black.opacity(0.82)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(article.categoryName)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Brand.categoryColor(for: article.categoryName).opacity(0.9), in: Capsule())
                        .foregroundStyle(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(article.readTimeLabel)
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.white)
                }

                Text(article.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.9), radius: 8, y: 2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
    }
}

// MARK: - GlassNewsArticleRow

private struct GlassNewsArticleRow: View {
    let article: Article

    var body: some View {
        HStack(spacing: 14) {
            ArticleImageView(url: article.imageURL)
                .frame(width: 62, height: 62)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1))

            VStack(alignment: .leading, spacing: 5) {
                Text(article.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(article.categoryName)
                        .lineLimit(1)

                    Circle()
                        .fill(.white.opacity(0.42))
                        .frame(width: 4, height: 4)

                    Text(article.date, style: .date)
                        .lineLimit(1)
                }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.62))
                .frame(width: 58, height: 58)
                .background(.white.opacity(0.08), in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
        }
        .padding(12)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))
        }
    }
}

// MARK: - GlassErrorView

private struct GlassErrorView: View {
    let message: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.6))
            Text("Kan niet laden")
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Color hex helper

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
