//
//  Localization.swift
//  CowsAndBulls
//

import Foundation

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
    let locale = languageCode == "system" ? Locale.current : Locale(identifier: languageCode)
    return String(format: format, locale: locale, arguments: args)
}
