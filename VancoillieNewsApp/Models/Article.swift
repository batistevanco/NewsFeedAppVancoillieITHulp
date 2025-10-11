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
}

struct Category: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
}
