import Foundation

enum AppLocalizer {
    static var currentLanguageIdentifier: String {
        UserDefaults.standard.string(forKey: "preferredInterfaceLanguage") ?? InterfaceLanguage.defaultInterfaceLanguage.rawValue
    }

    static func string(_ key: String) -> String {
        let localized = localizedBundle.localizedString(forKey: key, value: key, table: nil)
        if localized != key {
            return localized
        }

        let english = englishBundle.localizedString(forKey: key, value: key, table: nil)
        if english != key {
            return english
        }

        return localized
    }

    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(
            format: string(key),
            locale: Locale(identifier: currentLanguageIdentifier),
            arguments: arguments
        )
    }

    private static var localizedBundle: Bundle {
        let identifier = currentLanguageIdentifier

        if let path = Bundle.main.path(forResource: identifier, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        if let fallback = identifier.split(separator: "-").first.map(String.init),
           let path = Bundle.main.path(forResource: fallback, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        return .main
    }

    private static var englishBundle: Bundle {
        if let path = Bundle.main.path(forResource: InterfaceLanguage.english.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        return .main
    }
}
