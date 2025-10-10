import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark:  return .dark
        case .system: return nil
        }
    }

    var localizedLabel: String {
        switch self {
        case .light:  return NSLocalizedString("theme.light", comment: "")
        case .dark:   return NSLocalizedString("theme.dark", comment: "")
        case .system: return NSLocalizedString("theme.auto", comment: "")
        }
    }
}
