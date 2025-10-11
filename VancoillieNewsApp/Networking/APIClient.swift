import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}

    struct APIError: LocalizedError { let errorDescription: String? }

    func fetchArticles(locale: String, categoryID: Int?) async throws -> [Article] {
        var comps = URLComponents(url: NetworkConfig.baseURL.appendingPathComponent("api.php"), resolvingAgainstBaseURL: false)!
        var q: [URLQueryItem] = [ .init(name: "action", value: "articles"),
                                  .init(name: "lang", value: locale) ]
        if let id = categoryID {
            q.append(.init(name: "category_id", value: String(id)))
        }
        comps.queryItems = q
        guard let url = comps.url else { throw APIError(errorDescription: "Bad URL") }

        var req = URLRequest(url: url)
        req.cachePolicy = .reloadRevalidatingCacheData
        let (data, resp) = try await NetworkConfig.sharedSession.data(for: req)

        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError(errorDescription: "HTTP error \((resp as? HTTPURLResponse)?.statusCode ?? -1)")
        }
        let items = try JSONDecoder.iso8601().decode([Article].self, from: data)
        return items
    }

    // Optioneel: lightweight HEAD om snelle “not modified” te detecteren
    func hasChangedSince(locale: String, categoryID: Int?, etag: String?) async -> Bool {
        // Kun je later uitbreiden als je server ETag/Last-Modified zou sturen.
        return true
    }
}
