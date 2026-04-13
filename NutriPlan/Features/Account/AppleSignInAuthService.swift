import Foundation
import AuthenticationServices
import UIKit

struct AppleIdentity: Equatable {
    let userID: String
    let email: String?
    let displayName: String?
}

enum AppleSignInServiceError: LocalizedError {
    case canceled
    case missingPresentationAnchor
    case invalidCredential
    case anotherRequestInProgress
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .canceled:
            return "Вход через Apple был отменён."
        case .missingPresentationAnchor:
            return "Не удалось открыть системное окно авторизации."
        case .invalidCredential:
            return "Не удалось получить данные аккаунта Apple."
        case .anotherRequestInProgress:
            return "Запрос авторизации уже выполняется."
        case .unknown(let message):
            return message
        }
    }
}

protocol AppleSignInAuthService {
    func signIn(completion: @escaping (Result<AppleIdentity, Error>) -> Void)
}

final class SignInWithAppleAuthService: NSObject, AppleSignInAuthService {
    private var pendingCompletion: ((Result<AppleIdentity, Error>) -> Void)?

    func signIn(completion: @escaping (Result<AppleIdentity, Error>) -> Void) {
        guard pendingCompletion == nil else {
            completion(.failure(AppleSignInServiceError.anotherRequestInProgress))
            return
        }

        pendingCompletion = completion

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    private func finish(with result: Result<AppleIdentity, Error>) {
        let completion = pendingCompletion
        pendingCompletion = nil

        DispatchQueue.main.async {
            completion?(result)
        }
    }

    private func makeDisplayName(from fullName: PersonNameComponents?) -> String? {
        guard let fullName else { return nil }

        let formatter = PersonNameComponentsFormatter()
        let value = formatter.string(from: fullName).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func presentationAnchor() -> ASPresentationAnchor? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        for scene in scenes {
            if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
                return keyWindow
            }

            if let firstWindow = scene.windows.first {
                return firstWindow
            }
        }

        return nil
    }
}

extension SignInWithAppleAuthService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(with: .failure(AppleSignInServiceError.invalidCredential))
            return
        }

        let identity = AppleIdentity(
            userID: credential.user,
            email: credential.email,
            displayName: makeDisplayName(from: credential.fullName)
        )

        finish(with: .success(identity))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authorizationError = error as? ASAuthorizationError {
            switch authorizationError.code {
            case .canceled:
                finish(with: .failure(AppleSignInServiceError.canceled))
                return
            default:
                break
            }
        }

        finish(with: .failure(AppleSignInServiceError.unknown(error.localizedDescription)))
    }
}

extension SignInWithAppleAuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        presentationAnchor() ?? ASPresentationAnchor()
    }
}
