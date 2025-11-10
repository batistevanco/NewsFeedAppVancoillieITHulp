import SwiftUI

struct WatchOverviewView: View {
    @EnvironmentObject var vm: WatchArticlesViewModel

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Laden…")
                } else if let msg = vm.errorMessage {
                    VStack(spacing: 8) {
                        Text("Kon artikels niet laden")
                            .font(.headline)
                        Text(msg)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Button("Opnieuw") {
                            Task { await vm.load() }
                        }
                    }
                } else if vm.articlesThisWeek.isEmpty {
                    Text("Geen artikels deze week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            // top header
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Vancoillie News")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Color(red: 0.02, green: 0.4, blue: 1.0))
                                    Text("Deze week")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color.gray.opacity(0.8))
                                }
                                Spacer()
                                Button {
                                    Task {
                                        await vm.load(forceRefresh: true)
                                    }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 4)

                            ForEach(vm.articlesThisWeek) { article in
                                NavigationLink {
                                    WatchArticleDetailView(article: article)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(article.title)
                                                .font(.headline)
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(3) // laat tot 3 regels toe
                                                .minimumScaleFactor(0.8) // tekst krimpt lichtjes als het net niet past
                                            Text(article.categoryName)
                                                .font(.caption2)
                                                .foregroundColor(Color.gray.opacity(0.7))
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(red: 0.96, green: 0.97, blue: 1.0))
                                    )
                                }
                                .padding(.horizontal, 12)
                            }
                            .padding(.bottom, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    .refreshable {
                        await vm.load(forceRefresh: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .task {
                if vm.articlesThisWeek.isEmpty && !vm.isLoading {
                    await vm.load(forceRefresh: true)
                } else {
                    // zelfs als er al iets stond, kan je forceren:
                    await vm.load(forceRefresh: true)
                }
            }
            .onAppear {
                Task {
                    await vm.load(forceRefresh: true)
                }
            }
            .background(Color.white.ignoresSafeArea())
        }
    }
}
