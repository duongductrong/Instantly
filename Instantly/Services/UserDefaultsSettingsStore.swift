import Foundation

final class UserDefaultsSettingsStore {
    private let defaults: UserDefaults
    private let payloadKey = "instantly.settings.payload"
    private let schemaVersionKey = "instantly.settings.schema-version"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppSettings {
        guard let data = defaults.data(forKey: payloadKey) else {
            return AppSettings.defaultValue
        }

        let storedSchemaVersion = defaults.integer(forKey: schemaVersionKey)
        guard storedSchemaVersion == AppSettings.currentSchemaVersion else {
            reset()
            return AppSettings.defaultValue
        }

        do {
            let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
            guard decoded.schemaVersion == AppSettings.currentSchemaVersion else {
                reset()
                return AppSettings.defaultValue
            }
            return decoded
        } catch {
            reset()
            return AppSettings.defaultValue
        }
    }

    func save(_ settings: AppSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: payloadKey)
            defaults.set(settings.schemaVersion, forKey: schemaVersionKey)
        } catch {
            // Keep app operational even if persistence fails.
        }
    }

    func reset() {
        defaults.removeObject(forKey: payloadKey)
        defaults.removeObject(forKey: schemaVersionKey)
    }
}
