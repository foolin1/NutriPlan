import SwiftUI

struct PlanView: View {
    @ObservedObject var vm: PlanViewModel
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let plannedSummary = vm.daySummary()
        let nutrientFocus = appState.userProfile?.nutrientFocus ?? .none
        let optimization = DayPlanOptimizer.evaluate(
            meals: vm.dayPlan.meals,
            goal: appState.nutritionGoal,
            foodsById: vm.foodsById,
            nutrientFocus: nutrientFocus
        )

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    topHeader

                    SectionTitleView(
                        "Day optimization",
                        subtitle: "The planner now chooses the best combination of meals for the whole day, not each meal independently."
                    )

                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Daily score")
                                    .font(.headline)

                                Spacer()

                                StatPill(text: "\(Int(optimization.totalScore.rounded())) / 100")
                            }

                            Text(dayOptimizationSummary(for: optimization))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Divider()

                            InfoValueRow(
                                title: "Target calories",
                                value: "\(Int(optimization.targetCalories.rounded())) kcal"
                            )
                            InfoValueRow(
                                title: "Actual calories",
                                value: "\(Int(optimization.actualCalories.rounded())) kcal"
                            )

                            InfoValueRow(
                                title: "Target protein",
                                value: String(format: "%.1f g", optimization.targetProtein)
                            )
                            InfoValueRow(
                                title: "Actual protein",
                                value: String(format: "%.1f g", optimization.actualProtein)
                            )

                            InfoValueRow(
                                title: "Target fat",
                                value: String(format: "%.1f g", optimization.targetFat)
                            )
                            InfoValueRow(
                                title: "Actual fat",
                                value: String(format: "%.1f g", optimization.actualFat)
                            )

                            InfoValueRow(
                                title: "Target carbs",
                                value: String(format: "%.1f g", optimization.targetCarbs)
                            )
                            InfoValueRow(
                                title: "Actual carbs",
                                value: String(format: "%.1f g", optimization.actualCarbs)
                            )

                            Divider()

                            InfoValueRow(
                                title: "Coverage bonus",
                                value: String(format: "+%.1f", optimization.coverageBonus)
                            )
                            InfoValueRow(
                                title: "Meal quality bonus",
                                value: String(format: "+%.1f", optimization.mealQualityBonus)
                            )

                            if optimization.nutrientBonus > 0 {
                                InfoValueRow(
                                    title: "Nutrient bonus",
                                    value: String(format: "+%.1f", optimization.nutrientBonus)
                                )
                            }

                            if optimization.ironAmount > 0 {
                                InfoValueRow(
                                    title: "Iron in plan",
                                    value: String(format: "%.2f mg", optimization.ironAmount)
                                )
                            }
                        }
                    }

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

                Text("The plan is generated as an optimized combination of meals for the whole day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func dayOptimizationSummary(for breakdown: DayPlanScoreBreakdown) -> String {
        if breakdown.totalScore >= 90 {
            return "The full-day combination is very close to the daily target."
        } else if breakdown.totalScore >= 75 {
            return "The full-day combination is good, with moderate deviation from the daily target."
        } else {
            return "The planner found an acceptable daily combination, but deviations are more noticeable."
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
