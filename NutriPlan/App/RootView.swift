import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if !appState.isLoaded {
                launchStateView
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
        }
    }

    private var launchStateView: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)

                Text("NutriPlan")
                    .font(.largeTitle.weight(.bold))

                Text("Подготавливаем данные приложения")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ProgressView()
                    .padding(.top, 4)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}
