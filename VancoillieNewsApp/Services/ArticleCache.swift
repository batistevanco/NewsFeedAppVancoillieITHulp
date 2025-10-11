//
//  ArticleCache.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 11/10/2025.
//


import Foundation

struct ArticleCache {
    private static var cachesDir: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    private static func key(lang: String, categoryID: Int?) -> String {
        if let id = categoryID { return "articles_\(lang)_cat\(id).json" }
        return "articles_\(lang)_all.json"
    }

    static func load(lang: String, categoryID: Int?) -> [Article]? {
        let url = cachesDir.appendingPathComponent(key(lang: lang, categoryID: categoryID))
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.iso8601().decode([Article].self, from: data)
    }

    static func save(_ articles: [Article], lang: String, categoryID: Int?) {
        let url = cachesDir.appendingPathComponent(key(lang: lang, categoryID: categoryID))
        if let data = try? JSONEncoder().encode(articles) {
            try? data.write(to: url, options: [.atomic])
        }
    }
}

extension JSONDecoder {
    static func iso8601() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}