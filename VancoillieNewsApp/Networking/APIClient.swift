import Foundation

enum APIError: Error { case badURL, server, invalidResponse }

final class APIClient {
    static let shared = APIClient()
    private init(){}

    private let base = URL(string: "https://www.vancoillieithulp.be/news")!
    
    func fetchCategories(locale: String) async throws -> [Category] {
        var comps = URLComponents(url: base.appendingPathComponent("api.php"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [ URLQueryItem(name: "action", value: "categories"),
                             URLQueryItem(name: "lang", value: locale) ]
        let (data, resp) = try await URLSession.shared.data(from: guardURL(comps))
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.server }
        return try JSONDecoder().decode([Category].self, from: data)
    }

    func fetchArticles(locale: String, categoryID: Int?) async throws -> [Article] {
        var comps = URLComponents(url: base.appendingPathComponent("api.php"), resolvingAgainstBaseURL: false)!
        var items = [ URLQueryItem(name: "action", value: "articles"),
                      URLQueryItem(name: "lang", value: locale) ]
        if let cid = categoryID { items.append(URLQueryItem(name: "category_id", value: "\(cid)")) }
        comps.queryItems = items

        let (data, resp) = try await URLSession.shared.data(from: guardURL(comps))
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.server }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Article].self, from: data)
    }

    private func guardURL(_ comps: URLComponents?) throws -> URL {
        guard let url = comps?.url else { throw APIError.badURL }
        return url
    }
}
