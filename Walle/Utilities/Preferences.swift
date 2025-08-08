//
//  Preferences.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import Foundation

struct Preferences: Codable, Equatable {
    var hideAppAfterApply: Bool
    var launchAtLogin: Bool
    var defaultAspect: AspectMode

    enum AspectMode: String, Codable {
        case fit
        case fill
        case original
    }
}

enum PreferencesStore {
    private static let key = "app.preferences.v1"

    static func load() -> Preferences {
        if let data = UserDefaults.standard.data(forKey: key),
           let prefs = try? JSONDecoder().decode(Preferences.self, from: data) {
            return prefs
        }
        return Preferences(hideAppAfterApply: true, launchAtLogin: false, defaultAspect: .fill)
    }

    static func save(_ prefs: Preferences) {
        if let data = try? JSONEncoder().encode(prefs) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
