import Foundation

/// Persists simple user settings in UserDefaults.
struct SettingsStore {
    private let defaults = UserDefaults.standard
    private let key = "com.steipete.repobar.settings"

    func load() -> UserSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data)
        else {
            return UserSettings()
        }
        return settings
    }

    func save(_ settings: UserSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            self.defaults.set(data, forKey: self.key)
        }
    }
}
