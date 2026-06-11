import Foundation

struct Article: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let description: String
    let imageURL: URL?
    let fullURL: URL?
    let date: Date
    let categoryID: Int
    let categoryName: String

    var readTime: Int {
        let words = description.split(whereSeparator: \.isWhitespace).count
        return max(1, Int(ceil(Double(words) / 200.0)))
    }

    var readTimeLabel: String {
        readTime == 1 ? "1 min lezen" : "\(readTime) min lezen"
    }
}

struct Category: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
}
