import SwiftUI
import AuthenticationServices

struct SignInWithAppleActionButton: UIViewRepresentable {
    let onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.cornerRadius = 14
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleTap),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
    }

    final class Coordinator: NSObject {
        private let onTap: () -> Void

        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }

        @objc
        func handleTap() {
            onTap()
        }
    }
}
