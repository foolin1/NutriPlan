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
                    headerCard

                    if let goal = appState.nutritionGoal {
                        summarySection(
                            goal: goal,
                            plannedSummary: plannedSummary,
                            nutrientFocus: nutrientFocus
                        )
                    }

                    actionsSection

                    if vm.dayPlan.meals.isEmpty {
                        emptyPlanState
                    } else {
                        ForEach(MealType.allCases) { mealType in
                            let meals = vm.dayPlan.meals.filter { $0.type == mealType }

                            if !meals.isEmpty {
                                SectionTitleView(
                                    mealType.ruTitle,
                                    subtitle: "Блюда, подобранные для этой части дня."
                                )

                                VStack(spacing: 12) {
                                    ForEach(meals) { meal in
                                        NavigationLink {
                                            RecipeDetailView(mealId: meal.id, vm: vm)
                                        } label: {
                                            planMealCard(
                                                for: meal,
                                                nutrientFocus: nutrientFocus
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("План")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("План питания на день")
                    .font(.title2.weight(.bold))

                Text("Здесь можно просмотреть подобранные блюда, оценить итоговые показатели и при необходимости пересчитать или обновить текущий вариант плана.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func summarySection(
        goal: NutritionGoal,
        plannedSummary: NutritionSummary,
        nutrientFocus: NutrientFocus
    ) -> some View {
        SectionTitleView(
            "Сводка плана",
            subtitle: "Общий обзор текущего рациона на день."
        )

        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Текущая цель")
                    .font(.headline)

                InfoValueRow(title: "Калории", value: "\(goal.targetCalories) ккал")
                InfoValueRow(title: "Белки", value: "\(goal.proteinGrams) г")
                InfoValueRow(title: "Жиры", value: "\(goal.fatGrams) г")
                InfoValueRow(title: "Углеводы", value: "\(goal.carbsGrams) г")

                Divider()

                HStack {
                    Text("Что получилось в плане")
                        .font(.headline)

                    Spacer()

                    if nutrientFocus != .none {
                        StatPill(text: "Фокус: \(nutrientFocus.displayName)")
                    }
                }

                InfoValueRow(title: "Калории", value: "\(Int(plannedSummary.macros.calories.rounded())) ккал")
                InfoValueRow(title: "Белки", value: String(format: "%.1f г", plannedSummary.macros.protein))
                InfoValueRow(title: "Жиры", value: String(format: "%.1f г", plannedSummary.macros.fat))
                InfoValueRow(title: "Углеводы", value: String(format: "%.1f г", plannedSummary.macros.carbs))

                if nutrientFocus != .none,
                   let nutrient = NutrientCatalog.nutrient(for: nutrientFocus) {
                    Divider()
                    InfoValueRow(
                        title: "\(nutrient.name) в плане",
                        value: amountText(
                            plannedSummary.nutrients[nutrient.id, default: 0],
                            unit: nutrient.unit
                        )
                    )
                }
            }
        }
    }

    private var actionsSection: some View {
        Group {
            SectionTitleView(
                "Действия с планом",
                subtitle: "Можно пересчитать текущий вариант или подобрать другой хороший план на день."
            )

            AppCard {
                VStack(spacing: 12) {
                    Button {
                        vm.rebuildDayPlan(goal: appState.nutritionGoal)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Пересчитать")
                                    .font(.headline)

                                Text("Построить лучший вариант плана для текущего профиля.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.accentColor.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        vm.shuffleDayPlan(goal: appState.nutritionGoal)
                    } label: {
                        HStack {
                            Image(systemName: "shuffle.circle.fill")
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Подобрать другой вариант")
                                    .font(.headline)

                                Text("Показать другую подходящую комбинацию блюд на день.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.orange.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyPlanState: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("План пока не сформирован")
                    .font(.headline)

                Text("Нажми «Пересчитать» или «Подобрать другой вариант», чтобы приложение сформировало набор блюд на день.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func planMealCard(
        for meal: PlannedMeal,
        nutrientFocus: NutrientFocus
    ) -> some View {
        let summary = vm.summary(for: meal.recipe)
        let focusedAmount = NutrientCatalog.focusedAmount(
            in: summary.nutrients,
            for: nutrientFocus
        )

        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(vm.displayTitle(for: meal.recipe))
                            .font(.headline)

                        Text(meal.type.ruTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 6) {
                        if nutrientFocus != .none,
                           focusedAmount > 0,
                           let nutrient = NutrientCatalog.nutrient(for: nutrientFocus) {
                            StatPill(text: "\(nutrient.name): \(compactAmountText(focusedAmount, unit: nutrient.unit))")
                        }

                        if vm.isMealLogged(meal.id) {
                            StatPill(text: "В дневнике")
                        }
                    }
                }

                Divider()

                InfoValueRow(title: "Калории", value: "\(Int(summary.macros.calories.rounded())) ккал")
                InfoValueRow(title: "Белки", value: String(format: "%.1f г", summary.macros.protein))
                InfoValueRow(title: "Жиры", value: String(format: "%.1f г", summary.macros.fat))
                InfoValueRow(title: "Углеводы", value: String(format: "%.1f г", summary.macros.carbs))

                HStack {
                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func amountText(_ value: Double, unit: String) -> String {
        String(format: "%.1f %@", value, unit)
    }

    private func compactAmountText(_ value: Double, unit: String) -> String {
        if value >= 100 {
            return String(format: "%.0f %@", value, unit)
        } else {
            return String(format: "%.1f %@", value, unit)
        }
    }
}
