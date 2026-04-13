import Foundation

protocol UserProfileStore {
    func load() -> UserProfile?
    func save(_ profile: UserProfile)
    func clear()
}

final class UserDefaultsUserProfileStore: UserProfileStore {
    private enum GlobalLegacyKeys {
        static let current = "nutriplan.userProfile.v2"
        static let legacy = "nutriplan.userProfile"
    }

    private let userDefaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private let currentKey: String

    init(
        accountId: String,
        userDefaults: UserDefaults = .standard,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.userDefaults = userDefaults
        self.decoder = decoder
        self.encoder = encoder

        let namespace = Self.namespace(for: accountId)
        self.currentKey = "nutriplan.account.\(namespace).userProfile.v1"
    }

    func load() -> UserProfile? {
        if let scoped = loadProfile(forKey: currentKey) {
            return scoped
        }

        if let migrated = migrateFromLegacyStorage() {
            return migrated
        }

        return nil
    }

    func save(_ profile: UserProfile) {
        do {
            let data = try encoder.encode(profile)
            userDefaults.set(data, forKey: currentKey)
        } catch {
            print("Failed to save user profile: \(error)")
        }
    }

    func clear() {
        userDefaults.removeObject(forKey: currentKey)
    }

    private func migrateFromLegacyStorage() -> UserProfile? {
        if let profile = loadProfile(forKey: GlobalLegacyKeys.current) {
            save(profile)
            userDefaults.removeObject(forKey: GlobalLegacyKeys.current)
            return profile
        }

        if let legacyProfile = loadProfile(forKey: GlobalLegacyKeys.legacy) {
            save(legacyProfile)
            userDefaults.removeObject(forKey: GlobalLegacyKeys.legacy)
            return legacyProfile
        }

        return nil
    }

    private func loadProfile(forKey key: String) -> UserProfile? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        do {
            return try decoder.decode(UserProfile.self, from: data)
        } catch {
            print("Failed to load user profile for key '\(key)': \(error)")
            return nil
        }
    }

    private static func namespace(for accountId: String) -> String {
        accountId
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
    }
}
