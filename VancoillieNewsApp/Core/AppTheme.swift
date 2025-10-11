import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    // Gebruik je eigen vertaalde labels als je die al had
    var localizedLabel: String {
        switch self {
        case .system: return NSLocalizedString("settings.theme.system", comment: "")
        case .light:  return NSLocalizedString("settings.theme.light", comment: "")
        case .dark:   return NSLocalizedString("settings.theme.dark", comment: "")
        }
    }

    // ❗️Belangrijk: mapping naar SwiftUI color scheme
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
