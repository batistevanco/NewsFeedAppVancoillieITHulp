import Foundation

// Kleine helper om consistente decoders/encoders te gebruiken
private extension JSONDecoder {
    static func apiDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    // Pas aan indien je pad anders is
    private let baseURL = URL(string: "https://www.vancoillieithulp.be/news/")!

    // Gedeelde sessie met cache (sneller en zuiniger)
    private lazy var session: URLSession = {
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50 MB
            diskCapacity: 200 * 1024 * 1024,  // 200 MB
            diskPath: "URLCache"
        )
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .reloadRevalidatingCacheData
        cfg.urlCache = cache
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 40
        return URLSession(configuration: cfg)
    }()

    struct APIError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    // MARK: - Public API

    /// Haal categorieën op in de gevraagde taal ("nl" of "en").
    func fetchCategories(locale: String) async throws -> [Category] {
        var comps = URLComponents(url: baseURL.appendingPathComponent("api.php"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "action", value: "categories"),
            .init(name: "lang", value: normalized(locale))
        ]
        guard let url = comps.url else { throw APIError(message: "Bad URL (categories)") }

        var req = URLRequest(url: url)
        req.cachePolicy = .reloadRevalidatingCacheData

        let (data, resp) = try await session.data(for: req)
        try validate(resp, data: data)

        return try JSONDecoder.apiDecoder().decode([Category].self, from: data)
    }

    /// Haal artikels op in de gevraagde taal ("nl" of "en"), optioneel gefilterd op categorie.
    func fetchArticles(locale: String, categoryID: Int?) async throws -> [Article] {
        var comps = URLComponents(url: baseURL.appendingPathComponent("api.php"), resolvingAgainstBaseURL: false)!
        var items: [URLQueryItem] = [
            .init(name: "action", value: "articles"),
            .init(name: "lang", value: normalized(locale))
        ]
        if let cid = categoryID {
            items.append(.init(name: "category_id", value: String(cid)))
        }
        comps.queryItems = items
        guard let url = comps.url else { throw APIError(message: "Bad URL (articles)") }

        var req = URLRequest(url: url)
        req.cachePolicy = .reloadRevalidatingCacheData

        let (data, resp) = try await session.data(for: req)
        try validate(resp, data: data)

        return try JSONDecoder.apiDecoder().decode([Article].self, from: data)
    }

    // MARK: - Helpers

    private func normalized(_ locale: String) -> String {
        let lc = locale.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return (lc == "en") ? "en" : "nl" // fallback = nl
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError(message: "No HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            // Probeer foutboodschap uit backend te lezen voor debugging
            let text = String(data: data, encoding: .utf8) ?? ""
            throw APIError(message: "HTTP \(http.statusCode): \(text)")
        }
    }
}
