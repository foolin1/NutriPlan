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
                            "Сводка плана",
                            subtitle: "Общий обзор текущего рациона на день."
                        )

                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Текущая цель")
                                    .font(.headline)

                                InfoValueRow(title: "Калории", value: "\(goal.targetCalories) ккал")
                                InfoValueRow(title: "Белки", value: "\(goal.proteinGrams) г")
                                InfoValueRow(title: "Жиры", value: "\(goal.fatGrams) г")
                                InfoValueRow(title: "Углеводы", value: "\(goal.carbsGrams) г")

                                Divider()

                                Text("Что получилось в плане")
                                    .font(.headline)

                                InfoValueRow(title: "Калории", value: "\(Int(plannedSummary.macros.calories)) ккал")
                                InfoValueRow(title: "Белки", value: String(format: "%.1f г", plannedSummary.macros.protein))
                                InfoValueRow(title: "Жиры", value: String(format: "%.1f г", plannedSummary.macros.fat))
                                InfoValueRow(title: "Углеводы", value: String(format: "%.1f г", plannedSummary.macros.carbs))

                                if nutrientFocus == .iron {
                                    Divider()
                                    InfoValueRow(
                                        title: "Железо в плане",
                                        value: String(format: "%.2f мг", plannedSummary.nutrients["iron", default: 0])
                                    )
                                }
                            }
                        }
                    }

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
            .navigationTitle("План")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var topHeader: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("План питания на день")
                    .font(.title2.weight(.bold))

                Text("Здесь можно просмотреть подобранные блюда и при необходимости пересчитать или заменить текущий вариант плана.")
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

                        Text(meal.type.ruTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 6) {
                        if nutrientFocus == .iron && ironAmount >= 3.0 {
                            StatPill(text: "Поддержка железа")
                        }

                        if vm.isMealLogged(meal.id) {
                            StatPill(text: "В дневнике")
                        }
                    }
                }

                Divider()

                InfoValueRow(title: "Калории", value: "\(Int(summary.macros.calories)) ккал")
                InfoValueRow(title: "Белки", value: String(format: "%.1f г", summary.macros.protein))
                InfoValueRow(title: "Жиры", value: String(format: "%.1f г", summary.macros.fat))
                InfoValueRow(title: "Углеводы", value: String(format: "%.1f г", summary.macros.carbs))

                if nutrientFocus == .iron, let iron = summary.nutrients["iron"] {
                    InfoValueRow(title: "Железо", value: String(format: "%.2f мг", iron))
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
