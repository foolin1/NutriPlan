import Foundation

enum AppAccountKind: String, Codable {
    case firebaseEmail
}

struct AppAccount: Codable, Equatable {
    let id: String
    let kind: AppAccountKind
    let createdAt: Date
    let email: String?
    let displayName: String?
    let linkedAt: Date?

    var kindTitle: String {
        switch kind {
        case .firebaseEmail:
            return "Аккаунт по email"
        }
    }

    var authSubtitle: String {
        switch kind {
        case .firebaseEmail:
            return "Вход выполнен через email и пароль. История и профиль привязаны к стабильному uid пользователя."
        }
    }

    var syncStatusTitle: String {
        "Локально + готово к cloud sync"
    }

    var isGuest: Bool {
        false
    }

    var supportsCloudSync: Bool {
        true
    }

    var shortId: String {
        String(id.prefix(8)).uppercased()
    }

    var displayNameOrFallback: String {
        if let displayName, !displayName.isEmpty {
            return displayName
        }

        if let email, !email.isEmpty {
            return email
        }

        return kindTitle
    }
}

protocol AppAccountStore {
    func syncAuthenticatedAccount(
        uid: String,
        email: String?,
        displayName: String?
    ) -> AppAccount
    func clearAccount()
}

final class UserDefaultsAppAccountStore: AppAccountStore {
    private enum Keys {
        static let currentAccount = "nutriplan.currentAccount.v2"
    }

    private let userDefaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        userDefaults: UserDefaults = .standard,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.userDefaults = userDefaults
        self.decoder = decoder
        self.encoder = encoder
    }

    func syncAuthenticatedAccount(
        uid: String,
        email: String?,
        displayName: String?
    ) -> AppAccount {
        let existing = loadAccount()

        let account = AppAccount(
            id: uid,
            kind: .firebaseEmail,
            createdAt: existing?.id == uid ? existing?.createdAt ?? Date() : Date(),
            email: email ?? existing?.email,
            displayName: displayName ?? existing?.displayName,
            linkedAt: existing?.id == uid ? existing?.linkedAt ?? Date() : Date()
        )

        save(account)
        return account
    }

    func clearAccount() {
        userDefaults.removeObject(forKey: Keys.currentAccount)
    }

    private func loadAccount() -> AppAccount? {
        guard let data = userDefaults.data(forKey: Keys.currentAccount) else {
            return nil
        }

        do {
            return try decoder.decode(AppAccount.self, from: data)
        } catch {
            print("Failed to load account: \(error)")
            return nil
        }
    }

    private func save(_ account: AppAccount) {
        do {
            let data = try encoder.encode(account)
            userDefaults.set(data, forKey: Keys.currentAccount)
        } catch {
            print("Failed to save account: \(error)")
        }
    }
}
