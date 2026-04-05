import SwiftUI

struct ContentView: View {

    @StateObject private var vm = PlanViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var didInitialBuild = false

    var body: some View {
        let plannedSummary = vm.daySummary()
        let actualSummary = vm.actualSummary()
        let adjustment = vm.adjustmentRecommendation()
        let nutrientFocus = appState.userProfile?.nutrientFocus ?? .none

        NavigationStack {
            List {
                if let goal = appState.nutritionGoal {
                    Section("Your daily target") {
                        GoalInfoRow(title: "Calories", value: "\(goal.targetCalories) kcal")
                        GoalInfoRow(title: "Protein", value: "\(goal.proteinGrams) g")
                        GoalInfoRow(title: "Fat", value: "\(goal.fatGrams) g")
                        GoalInfoRow(title: "Carbs", value: "\(goal.carbsGrams) g")
                    }

                    if nutrientFocus == .iron {
                        Section("Micronutrient focus") {
                            GoalInfoRow(title: "Focus", value: nutrientFocus.shortTitle)
                            GoalInfoRow(title: "Planned iron", value: String(format: "%.2f mg", plannedSummary.nutrients["iron", default: 0]))

                            if !vm.diaryDay.entries.isEmpty {
                                GoalInfoRow(title: "Actual iron", value: String(format: "%.2f mg", actualSummary.nutrients["iron", default: 0]))
                            }

                            Text("The planner prefers iron-rich meals when possible.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Planned total") {
                        GoalInfoRow(title: "Calories", value: "\(Int(plannedSummary.macros.calories)) kcal")
                        GoalInfoRow(title: "Protein", value: String(format: "%.1f g", plannedSummary.macros.protein))
                        GoalInfoRow(title: "Fat", value: String(format: "%.1f g", plannedSummary.macros.fat))
                        GoalInfoRow(title: "Carbs", value: String(format: "%.1f g", plannedSummary.macros.carbs))
                    }

                    if !vm.diaryDay.entries.isEmpty {
                        Section("Actual total") {
                            GoalInfoRow(title: "Calories", value: "\(Int(actualSummary.macros.calories)) kcal")
                            GoalInfoRow(title: "Protein", value: String(format: "%.1f g", actualSummary.macros.protein))
                            GoalInfoRow(title: "Fat", value: String(format: "%.1f g", actualSummary.macros.fat))
                            GoalInfoRow(title: "Carbs", value: String(format: "%.1f g", actualSummary.macros.carbs))
                        }
                    }
                }

                if let adjustment {
                    Section("Tomorrow recommendation") {
                        Text(adjustment.statusTitle)
                            .font(.headline)

                        Text(adjustment.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        GoalInfoRow(title: "Calories", value: "\(adjustment.nextDayGoal.targetCalories) kcal")
                        GoalInfoRow(title: "Protein", value: "\(adjustment.nextDayGoal.proteinGrams) g")
                        GoalInfoRow(title: "Fat", value: "\(adjustment.nextDayGoal.fatGrams) g")
                        GoalInfoRow(title: "Carbs", value: "\(adjustment.nextDayGoal.carbsGrams) g")

                        if !adjustment.hints.isEmpty {
                            ForEach(adjustment.hints, id: \.self) { hint in
                                Text("• \(hint)")
                                    .font(.caption)
                            }
                        }
                    }
                }

                Section {
                    NavigationLink("Open Shopping List") {
                        ShoppingListView(items: shoppingItems)
                    }

                    NavigationLink("Open Diary") {
                        DiaryView(vm: vm)
                    }

                    if !vm.diaryDay.entries.isEmpty {
                        NavigationLink("Open Plan vs Actual") {
                            PlanComparisonView(vm: vm)
                        }
                    }
                }

                Section("Today’s meals") {
                    ForEach(vm.dayPlan.meals) { meal in
                        NavigationLink {
                            RecipeDetailView(mealId: meal.id, vm: vm)
                        } label: {
                            let s = vm.summary(for: meal.recipe)
                            let ironAmount = vm.recipeIronAmount(for: meal.recipe)

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(meal.type.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    if nutrientFocus == .iron && ironAmount >= 3.0 {
                                        Text("Iron support")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.thinMaterial)
                                            .clipShape(Capsule())
                                    }

                                    if vm.isMealLogged(meal.id) {
                                        Text("Added to diary")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Text(vm.displayTitle(for: meal.recipe))
                                    .font(.headline)

                                Text("Calories: \(Int(s.macros.calories))")
                                    .font(.subheadline)

                                Text("P: \(s.macros.protein, specifier: "%.1f")  F: \(s.macros.fat, specifier: "%.1f")  C: \(s.macros.carbs, specifier: "%.1f")")
                                    .font(.caption)

                                if let iron = s.nutrients["iron"], nutrientFocus == .iron {
                                    Text("Iron: \(iron, specifier: "%.2f") mg")
                                        .font(.caption2)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        appState.resetProfile()
                    }
                }
            }
            .onAppear {
                vm.applyProfile(appState.userProfile)

                if !didInitialBuild {
                    vm.rebuildDayPlan(goal: appState.nutritionGoal)
                    didInitialBuild = true
                }
            }
            .onChange(of: appState.userProfile) { newValue in
                vm.applyProfile(newValue)
                vm.rebuildDayPlan(goal: appState.nutritionGoal)
            }
            .onChange(of: appState.nutritionGoal) { newValue in
                vm.rebuildDayPlan(goal: newValue)
            }
        }
    }

    private var shoppingItems: [ShoppingItem] {
        ShoppingListBuilder.build(
            recipes: vm.dayPlan.meals.map { $0.recipe },
            foodsById: vm.foodsById
        )
    }
}

private struct GoalInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
