import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var planViewModel = PlanViewModel()

    var body: some View {
        TabView {
            TodayView(vm: planViewModel)
                .tabItem {
                    Label("Сегодня", systemImage: "sun.max")
                }

            PlanView(vm: planViewModel)
                .tabItem {
                    Label("План", systemImage: "fork.knife")
                }

            NavigationStack {
                ShoppingListView(items: shoppingItems)
            }
            .tabItem {
                Label("Покупки", systemImage: "cart")
            }

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.crop.circle")
                }
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

    private var shoppingItems: [ShoppingItem] {
        ShoppingListBuilder.build(
            recipes: planViewModel.dayPlan.meals.map(\.recipe),
            foodsById: planViewModel.foodsById
        )
    }

    private func configureSession() {
        planViewModel.configureSession(
            profile: appState.userProfile,
            goal: appState.nutritionGoal
        )
    }
}
