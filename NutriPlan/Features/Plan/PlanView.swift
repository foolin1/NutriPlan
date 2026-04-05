import SwiftUI

struct PlanView: View {
    @ObservedObject var vm: PlanViewModel
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let plannedSummary = vm.daySummary()
        let nutrientFocus = appState.userProfile?.nutrientFocus ?? .none

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    topHeader

                    if let goal = appState.nutritionGoal {
                        SectionTitleView(
                            "Plan summary",
                            subtitle: "Overview of the generated nutrition plan for the current day."
                        )

                        AppCard {
                            Text("Current target")
                                .font(.headline)

                            InfoValueRow(title: "Target calories", value: "\(goal.targetCalories) kcal")
                            InfoValueRow(title: "Planned calories", value: "\(Int(plannedSummary.macros.calories)) kcal")
                            InfoValueRow(title: "Protein", value: String(format: "%.1f g", plannedSummary.macros.protein))
                            InfoValueRow(title: "Fat", value: String(format: "%.1f g", plannedSummary.macros.fat))
                            InfoValueRow(title: "Carbs", value: String(format: "%.1f g", plannedSummary.macros.carbs))

                            if nutrientFocus == .iron {
                                Divider()
                                InfoValueRow(
                                    title: "Iron in plan",
                                    value: String(format: "%.2f mg", plannedSummary.nutrients["iron", default: 0])
                                )
                            }
                        }
                    }

                    ForEach(MealType.allCases) { mealType in
                        let meals = vm.dayPlan.meals.filter { $0.type == mealType }

                        if !meals.isEmpty {
                            SectionTitleView(
                                mealType.rawValue,
                                subtitle: "Meals generated for this part of the day."
                            )

                            VStack(spacing: 12) {
                                ForEach(meals) { meal in
                                    NavigationLink {
                                        RecipeDetailView(mealId: meal.id, vm: vm)
                                    } label: {
                                        planMealCard(for: meal, nutrientFocus: nutrientFocus)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Rebuild") {
                        vm.rebuildDayPlan(goal: appState.nutritionGoal)
                    }
                }
            }
        }
    }

    private var topHeader: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily meal plan")
                    .font(.title2.weight(.bold))

                Text("Here you can review the generated meals, inspect recipe composition and open meal details.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func planMealCard(for meal: PlannedMeal, nutrientFocus: NutrientFocus) -> some View {
        let summary = vm.summary(for: meal.recipe)
        let ironAmount = vm.recipeIronAmount(for: meal.recipe)

        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(vm.displayTitle(for: meal.recipe))
                            .font(.headline)

                        Text(meal.type.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 6) {
                        if nutrientFocus == .iron && ironAmount >= 3.0 {
                            StatPill(text: "Iron support")
                        }

                        if vm.isMealLogged(meal.id) {
                            StatPill(text: "Added to diary")
                        }
                    }
                }

                Divider()

                InfoValueRow(title: "Calories", value: "\(Int(summary.macros.calories)) kcal")
                InfoValueRow(title: "Protein", value: String(format: "%.1f g", summary.macros.protein))
                InfoValueRow(title: "Fat", value: String(format: "%.1f g", summary.macros.fat))
                InfoValueRow(title: "Carbs", value: String(format: "%.1f g", summary.macros.carbs))

                if nutrientFocus == .iron,
                   let iron = summary.nutrients["iron"] {
                    InfoValueRow(title: "Iron", value: String(format: "%.2f mg", iron))
                }

                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
