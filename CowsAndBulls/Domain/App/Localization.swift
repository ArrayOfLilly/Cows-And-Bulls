//
//  Localization.swift
//  CowsAndBulls
//

import Foundation

/// Returns a localized string for `key` and formats it with optional arguments.
/// The function respects the custom app language stored in `appLanguageCode`.
func localized(_ key: String, _ args: CVarArg...) -> String {
    let languageCode = UserDefaults.standard.string(forKey: "appLanguageCode") ?? "system"

    let bundle: Bundle
    if languageCode == "system" {
        bundle = .main
    } else if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let localizedBundle = Bundle(path: path) {
        bundle = localizedBundle
    } else {
        bundle = .main
    }

    let format = bundle.localizedString(forKey: key, value: key, table: nil)
    // Locale-aware String(format:) keeps number/date-like formatting correct per selected language.
    let locale = languageCode == "system" ? Locale.current : Locale(identifier: languageCode)
    return String(format: format, locale: locale, arguments: args)
}
