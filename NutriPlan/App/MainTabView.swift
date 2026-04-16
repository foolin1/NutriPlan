import SwiftUI

private enum MainTab: String, Hashable {
    case today
    case plan
    case shopping
    case profile
}

struct MainTabView: View {
    let accountId: String

    @EnvironmentObject private var appState: AppState
    @AppStorage("app.selectedTab") private var selectedTabRawValue: String = MainTab.today.rawValue
    @StateObject private var planViewModel: PlanViewModel

    init(accountId: String) {
        self.accountId = accountId
        _planViewModel = StateObject(
            wrappedValue: PlanViewModel(
                accountId: accountId,
                sessionStore: UserDefaultsPlanSessionStore(accountId: accountId),
                remoteDayStore: FirebaseDayRecordsRemoteStore()
            )
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            TodayView(vm: planViewModel)
                .tabItem {
                    Label("Сегодня", systemImage: "sun.max")
                }
                .tag(MainTab.today)

            PlanView(vm: planViewModel)
                .tabItem {
                    Label("План", systemImage: "fork.knife")
                }
                .tag(MainTab.plan)

            NavigationStack {
                ShoppingListView(vm: planViewModel)
            }
            .tabItem {
                Label("Покупки", systemImage: "cart")
            }
            .tag(MainTab.shopping)

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.crop.circle")
                }
                .tag(MainTab.profile)
        }
        .onAppear {
            configureSession()
        }
        .onChange(of: appState.userProfile) { _ in
            configureSession()
        }
        .onChange(of: appState.nutritionGoal) { newGoal in
            planViewModel.configureSession(
                profile: appState.userProfile,
                goal: newGoal
            )
        }
    }

    private var tabSelection: Binding<MainTab> {
        Binding(
            get: { MainTab(rawValue: selectedTabRawValue) ?? .today },
            set: { newValue in
                selectedTabRawValue = newValue.rawValue
            }
        )
    }

    private func configureSession() {
        planViewModel.configureSession(
            profile: appState.userProfile,
            goal: appState.nutritionGoal
        )
    }
}
