import SwiftUI

/// English, Arabic or the phone's language, chosen in Account and kept on the phone. SwiftUI text switches at once through the
/// environment; text built in code (`String(localized:)`) follows the saved choice the next time the app opens.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, english, arabic

    static let storageKey = "appLanguage"

    var id: Self { self }

    /// nil follows the phone.
    var code: String? {
        switch self {
        case .system: nil
        case .english: "en"
        case .arabic: "ar"
        }
    }

    /// Each language named in itself, so it can be found whatever the current language.
    var label: Text {
        switch self {
        case .system: Text("System")
        case .english: Text(verbatim: "English")
        case .arabic: Text(verbatim: "العربية")
        }
    }

    /// The locale the app runs in: the choice, or the phone's.
    var locale: Locale { code.map(Locale.init(identifier:)) ?? .autoupdatingCurrent }

    var layoutDirection: LayoutDirection {
        Locale.Language(identifier: locale.identifier).characterDirection == .rightToLeft ? .rightToLeft : .leftToRight
    }

    /// Saves the choice where iOS reads the app's language at launch (the same setting as Settings, Waffi, Language).
    func apply() {
        if let code {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }
}
