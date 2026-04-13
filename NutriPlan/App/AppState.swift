import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isLoaded = false
    @Published private(set) var account: AppAccount?
    @Published private(set) var userProfile: UserProfile? {
        didSet {
            recalculateNutritionGoal()
        }
    }
    @Published private(set) var nutritionGoal: NutritionGoal?
    @Published private(set) var profileSnapshots: [ProfileSnapshot] = []
    @Published private(set) var isAuthenticating = false
    @Published private(set) var isCloudProfileRestoreInProgress = false
    @Published private(set) var lastCloudProfileRestoreAt: Date?
    @Published private(set) var isCloudProfileLiveSyncActive = false
    @Published private(set) var lastCloudProfileEventAt: Date?

    @Published var authErrorMessage: String?
    @Published var authInfoMessage: String?

    private let accountStore: AppAccountStore
    private let authService: FirebaseEmailAuthService
    private let profileRemoteStore: UserProfileRemoteStore
    private let profileSnapshotsRemoteStore: ProfileSnapshotsRemoteStore

    private var profileStore: UserProfileStore?
    private var authListenerHandle: NSObjectProtocol?
    private var didBootstrap = false
    private var currentAuthenticatedUID: String?

    private var profileListenerToken: CloudListenerToken?
    private var profileSnapshotsListenerToken: CloudListenerToken?

    init(
        accountStore: AppAccountStore = UserDefaultsAppAccountStore(),
        authService: FirebaseEmailAuthService = DefaultFirebaseEmailAuthService(),
        profileRemoteStore: UserProfileRemoteStore = FirebaseUserProfileRemoteStore(),
        profileSnapshotsRemoteStore: ProfileSnapshotsRemoteStore = FirebaseProfileSnapshotsRemoteStore()
    ) {
        self.accountStore = accountStore
        self.authService = authService
        self.profileRemoteStore = profileRemoteStore
        self.profileSnapshotsRemoteStore = profileSnapshotsRemoteStore
    }

    deinit {
        if let authListenerHandle {
            authService.removeStateDidChangeListener(authListenerHandle)
        }

        profileListenerToken?.remove()
        profileSnapshotsListenerToken?.remove()
    }

    var hasProfile: Bool {
        userProfile != nil
    }

    var accountTitle: String {
        account?.kindTitle ?? "Аккаунт"
    }

    var accountShortId: String {
        account?.shortId ?? "—"
    }

    var isGuestAccount: Bool {
        account == nil
    }

    var accountSyncTitle: String {
        account?.syncStatusTitle ?? "Не авторизован"
    }

    var accountAuthSubtitle: String {
        account?.authSubtitle ?? "Выполни вход, чтобы профиль и история были привязаны к постоянному uid."
    }

    var supportsCloudSync: Bool {
        account?.supportsCloudSync ?? false
    }

    func bootstrapIfNeeded() {
        guard !didBootstrap else { return }
        didBootstrap = true

        applyAuthSession(authService.currentSession())

        authListenerHandle = authService.addStateDidChangeListener { [weak self] session in
            guard let self else { return }

            Task { @MainActor in
                self.applyAuthSession(session)
            }
        }

        isLoaded = true
    }

    func completeOnboarding(with profile: UserProfile) {
        saveProfile(profile)
    }

    func updateProfile(_ profile: UserProfile) {
        saveProfile(profile)
    }

    func resetProfile() {
        userProfile = nil
        nutritionGoal = nil
        profileStore?.clear()
    }

    func clearAuthMessages() {
        authErrorMessage = nil
        authInfoMessage = nil
    }

    func reloadCloudProfileData() {
        guard let uid = currentAuthenticatedUID else { return }
        restoreCloudProfileData(for: uid, interactive: true)
    }

    func signIn(email: String, password: String) {
        guard !isAuthenticating else { return }

        clearAuthMessages()
        isAuthenticating = true

        Task {
            do {
                _ = try await authService.signIn(email: email, password: password)
            } catch {
                await MainActor.run {
                    self.authErrorMessage = self.mapAuthError(error)
                    self.isAuthenticating = false
                }
                return
            }

            await MainActor.run {
                self.isAuthenticating = false
            }
        }
    }

    func signUp(email: String, password: String) {
        guard !isAuthenticating else { return }

        clearAuthMessages()
        isAuthenticating = true

        Task {
            do {
                _ = try await authService.signUp(email: email, password: password)
                await MainActor.run {
                    self.authInfoMessage = "Аккаунт создан. Теперь можно продолжать настройку профиля."
                }
            } catch {
                await MainActor.run {
                    self.authErrorMessage = self.mapAuthError(error)
                    self.isAuthenticating = false
                }
                return
            }

            await MainActor.run {
                self.isAuthenticating = false
            }
        }
    }

    func sendPasswordReset(email: String) {
        guard !isAuthenticating else { return }

        clearAuthMessages()
        isAuthenticating = true

        Task {
            do {
                try await authService.sendPasswordReset(email: email)
                await MainActor.run {
                    self.authInfoMessage = "Письмо для сброса пароля отправлено."
                    self.isAuthenticating = false
                }
            } catch {
                await MainActor.run {
                    self.authErrorMessage = self.mapAuthError(error)
                    self.isAuthenticating = false
                }
            }
        }
    }

    func signOut() {
        do {
            try authService.signOut()
            clearAuthMessages()
        } catch {
            authErrorMessage = mapAuthError(error)
        }
    }

    private func applyAuthSession(_ session: FirebaseUserSession?) {
        guard let session else {
            stopProfileLiveSync()
            currentAuthenticatedUID = nil
            account = nil
            userProfile = nil
            nutritionGoal = nil
            profileSnapshots = []
            profileStore = nil
            lastCloudProfileRestoreAt = nil
            lastCloudProfileEventAt = nil
            isCloudProfileRestoreInProgress = false
            return
        }

        currentAuthenticatedUID = session.uid

        let syncedAccount = accountStore.syncAuthenticatedAccount(
            uid: session.uid,
            email: session.email,
            displayName: session.displayName
        )

        account = syncedAccount

        let scopedProfileStore = UserDefaultsUserProfileStore(accountId: session.uid)
        profileStore = scopedProfileStore
        userProfile = scopedProfileStore.load()

        startProfileLiveSync(uid: session.uid)
        restoreCloudProfileData(for: session.uid, interactive: false)
    }

    private func startProfileLiveSync(uid: String) {
        stopProfileLiveSync()

        profileListenerToken = profileRemoteStore.observeProfile(uid: uid) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                guard self.currentAuthenticatedUID == uid else { return }

                switch result {
                case .success(let remoteProfile):
                    if let remoteProfile {
                        let currentFingerprint = self.userProfile.map(self.profileFingerprint)
                        let remoteFingerprint = self.profileFingerprint(remoteProfile)

                        if currentFingerprint != remoteFingerprint {
                            self.userProfile = remoteProfile
                            self.profileStore?.save(remoteProfile)
                        }
                    }

                    self.lastCloudProfileEventAt = Date()

                case .failure(let error):
                    print("Profile listener error: \(error)")
                }
            }
        }

        profileSnapshotsListenerToken = profileSnapshotsRemoteStore.observeSnapshots(uid: uid) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                guard self.currentAuthenticatedUID == uid else { return }

                switch result {
                case .success(let snapshots):
                    self.profileSnapshots = snapshots
                    self.lastCloudProfileEventAt = Date()

                case .failure(let error):
                    print("Profile snapshots listener error: \(error)")
                }
            }
        }

        isCloudProfileLiveSyncActive = true
    }

    private func stopProfileLiveSync() {
        profileListenerToken?.remove()
        profileSnapshotsListenerToken?.remove()
        profileListenerToken = nil
        profileSnapshotsListenerToken = nil
        isCloudProfileLiveSyncActive = false
    }

    private func restoreCloudProfileData(for uid: String, interactive: Bool) {
        if interactive {
            clearAuthMessages()
        }

        isCloudProfileRestoreInProgress = true

        Task {
            do {
                async let profileTask = profileRemoteStore.fetchProfile(uid: uid)
                async let snapshotsTask = profileSnapshotsRemoteStore.fetchSnapshots(uid: uid)

                let (remoteProfile, snapshots) = try await (profileTask, snapshotsTask)

                await MainActor.run {
                    guard self.currentAuthenticatedUID == uid else { return }

                    if let remoteProfile {
                        self.userProfile = remoteProfile
                        self.profileStore?.save(remoteProfile)
                    }

                    self.profileSnapshots = snapshots
                    self.lastCloudProfileRestoreAt = Date()
                    self.isCloudProfileRestoreInProgress = false

                    if interactive {
                        self.authInfoMessage = "Профиль и история профиля обновлены из облака."
                    }
                }
            } catch {
                await MainActor.run {
                    guard self.currentAuthenticatedUID == uid else { return }
                    self.isCloudProfileRestoreInProgress = false

                    if interactive {
                        self.authErrorMessage = "Не удалось обновить профиль из облака: \(error.localizedDescription)"
                    } else {
                        print("Failed to restore cloud profile data: \(error)")
                    }
                }
            }
        }
    }

    private func saveProfile(_ profile: UserProfile) {
        let previousProfile = userProfile
        let shouldAppendSnapshot = previousProfile.map(profileFingerprint) != profileFingerprint(profile)

        userProfile = profile
        profileStore?.save(profile)

        guard let uid = currentAuthenticatedUID else { return }

        Task {
            do {
                try await profileRemoteStore.saveProfile(profile, uid: uid)

                if shouldAppendSnapshot {
                    try await profileSnapshotsRemoteStore.appendSnapshot(profile, uid: uid)
                }

                await MainActor.run {
                    guard self.currentAuthenticatedUID == uid else { return }
                    self.lastCloudProfileRestoreAt = Date()
                }
            } catch {
                print("Failed to save remote profile or snapshot: \(error)")
            }
        }
    }

    private func recalculateNutritionGoal() {
        nutritionGoal = userProfile.map { GoalCalculator.calculate(for: $0) }
    }

    private func profileFingerprint(_ profile: UserProfile) -> String {
        let allergens = profile.excludedAllergens
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .sorted()
            .joined(separator: "|")

        let excludedProducts = profile.excludedProducts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .sorted()
            .joined(separator: "|")

        let excludedGroups = profile.excludedGroups
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .sorted()
            .joined(separator: "|")

        return [
            profile.sex.rawValue,
            String(profile.age),
            String(Int(profile.heightCm.rounded())),
            String(Int(profile.weightKg.rounded())),
            profile.activityLevel.rawValue,
            profile.goalType.rawValue,
            profile.nutrientFocus.displayName,
            allergens,
            excludedProducts,
            excludedGroups
        ].joined(separator: "#")
    }

    private func mapAuthError(_ error: Error) -> String {
        let nsError = error as NSError

        if nsError.domain == AuthErrorDomain,
           let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .invalidEmail:
                return "Некорректный email."
            case .wrongPassword:
                return "Неверный пароль."
            case .userNotFound:
                return "Пользователь с таким email не найден."
            case .emailAlreadyInUse:
                return "Этот email уже используется."
            case .weakPassword:
                return "Слишком слабый пароль. Используй не менее 8 символов."
            case .networkError:
                return "Проблема с сетью. Проверь подключение к интернету."
            case .tooManyRequests:
                return "Слишком много попыток. Попробуй позже."
            default:
                return nsError.localizedDescription
            }
        }

        return nsError.localizedDescription
    }
}
