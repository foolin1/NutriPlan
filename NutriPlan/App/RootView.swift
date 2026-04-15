import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    @State private var hasFinishedIntro = false
    @State private var didStartIntro = false

    var body: some View {
        Group {
            if shouldShowStartup {
                StartupIntroView()
            } else if appState.account == nil {
                AuthGateView()
            } else if appState.hasProfile, let accountId = appState.account?.id {
                MainTabView(accountId: accountId)
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            appState.bootstrapIfNeeded()
            startIntroIfNeeded()
        }
    }

    private var shouldShowStartup: Bool {
        !appState.isLoaded || !hasFinishedIntro
    }

    private func startIntroIfNeeded() {
        guard !didStartIntro else { return }
        didStartIntro = true

        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)

            await MainActor.run {
                hasFinishedIntro = true
            }
        }
    }
}
