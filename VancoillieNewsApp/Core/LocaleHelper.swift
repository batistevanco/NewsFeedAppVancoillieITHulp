import Foundation

enum LocaleHelper {
    static var appLangParam: String {
        // "nl" of "en" naar API sturen
        let code = Locale.current.language.languageCode?.identifier ?? "nl"
        return (code.lowercased().hasPrefix("nl")) ? "nl" : "en"
    }
}
