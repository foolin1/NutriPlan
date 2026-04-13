import Foundation
import FirebaseAuth

struct FirebaseUserSession: Equatable {
    let uid: String
    let email: String?
    let displayName: String?
}

protocol FirebaseEmailAuthService {
    func currentSession() -> FirebaseUserSession?
    func addStateDidChangeListener(
        _ listener: @escaping (FirebaseUserSession?) -> Void
    ) -> NSObjectProtocol
    func removeStateDidChangeListener(_ handle: NSObjectProtocol)

    func signUp(email: String, password: String) async throws -> FirebaseUserSession
    func signIn(email: String, password: String) async throws -> FirebaseUserSession
    func sendPasswordReset(email: String) async throws
    func signOut() throws
}

final class DefaultFirebaseEmailAuthService: FirebaseEmailAuthService {
    func currentSession() -> FirebaseUserSession? {
        Auth.auth().currentUser.map(mapUser)
    }

    func addStateDidChangeListener(
        _ listener: @escaping (FirebaseUserSession?) -> Void
    ) -> NSObjectProtocol {
        Auth.auth().addStateDidChangeListener { _, user in
            listener(user.map(self.mapUser))
        }
    }

    func removeStateDidChangeListener(_ handle: NSObjectProtocol) {
        Auth.auth().removeStateDidChangeListener(handle)
    }

    func signUp(email: String, password: String) async throws -> FirebaseUserSession {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let user = result?.user else {
                    continuation.resume(throwing: NSError(
                        domain: "NutriPlan.Auth",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Не удалось создать аккаунт."]
                    ))
                    return
                }

                continuation.resume(returning: self.mapUser(user))
            }
        }
    }

    func signIn(email: String, password: String) async throws -> FirebaseUserSession {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let user = result?.user else {
                    continuation.resume(throwing: NSError(
                        domain: "NutriPlan.Auth",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Не удалось выполнить вход."]
                    ))
                    return
                }

                continuation.resume(returning: self.mapUser(user))
            }
        }
    }

    func sendPasswordReset(email: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    private func mapUser(_ user: User) -> FirebaseUserSession {
        FirebaseUserSession(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName
        )
    }
}
