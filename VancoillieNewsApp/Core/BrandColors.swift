import SwiftUI

enum Brand {
    static let blue   = Color(red: 0/255, green: 123/255, blue: 255/255)
    static let accent = Color(red: 214/255, green: 73/255,  blue: 51/255)

    static func categoryColor(for name: String) -> Color {
        let lower = name.lowercased()
        if lower.contains("vancoillie")                                     { return Brand.blue }
        if lower.contains("tech") || lower.contains("technolog")            { return .blue }
        if lower.contains("sport")                                          { return Color(red: 0.15, green: 0.65, blue: 0.3) }
        if lower.contains("financ") || lower.contains("econom") || lower.contains("beurs") { return Color(red: 0.85, green: 0.55, blue: 0.05) }
        if lower.contains(" ai") || lower.contains("artifici") || lower.contains("intelligenti") { return .purple }
        if lower.contains("belgi")                                          { return Color(red: 0.8, green: 0.1, blue: 0.1) }
        if lower.contains("gaming") || lower.contains("game")              { return Color(red: 0.4, green: 0.2, blue: 0.8) }
        if lower.contains("wetenschap") || lower.contains("science")       { return .teal }
        if lower.contains("gezondheid") || lower.contains("health")        { return Color(red: 0.9, green: 0.3, blue: 0.4) }
        return Color.secondary
    }
}
