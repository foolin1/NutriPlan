import SwiftUI

struct TodayView: View {
    @ObservedObject var vm: PlanViewModel
    @EnvironmentObject private var appState: AppState

    private let actionColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        let plannedSummary = vm.daySummary()
        let actualSummary = vm.actualSummary()
        let adjustment = vm.adjustmentRecommendation()
        let nutrientFocus = appState.userProfile?.nutrientFocus ?? .none

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    if let goal = appState.nutritionGoal {
                        summarySection(
                            goal: goal,
                            plannedSummary: plannedSummary,
                            actualSummary: actualSummary,
                            nutrientFocus: nutrientFocus
                        )

                        micronutrientsSection(
                            plannedSummary: plannedSummary,
                            actualSummary: actualSummary,
                            nutrientFocus: nutrientFocus
                        )
                    }

                    actionsSection

                    if let adjustment {
                        SectionTitleView(
                            "Рекомендация на завтра",
                            subtitle: "Следующая цель с учётом сегодняшнего питания."
                        )

                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(adjustment.statusTitle)
                                    .font(.headline)

                                Text(adjustment.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Divider()

                                InfoValueRow(title: "Калории", value: "\(adjustment.nextDayGoal.targetCalories) ккал")
                                InfoValueRow(title: "Белки", value: "\(adjustment.nextDayGoal.proteinGrams) г")
                                InfoValueRow(title: "Жиры", value: "\(adjustment.nextDayGoal.fatGrams) г")
                                InfoValueRow(title: "Углеводы", value: "\(adjustment.nextDayGoal.carbsGrams) г")

                                if !adjustment.hints.isEmpty {
                                    Divider()

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Подсказки")
                                            .font(.subheadline.weight(.semibold))

                                        ForEach(adjustment.hints, id: \.self) { hint in
                                            Text("• \(hint)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    mealsSection(nutrientFocus: nutrientFocus)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Сегодня")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var headerSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Питание на сегодня")
                    .font(.title2.weight(.bold))

                Text("Здесь можно быстро посмотреть цель дня, сравнить план и факт, открыть дневник и при необходимости обновить данные аккаунта.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func summarySection(
        goal: NutritionGoal,
        plannedSummary: NutritionSummary,
        actualSummary: NutritionSummary,
        nutrientFocus: NutrientFocus
    ) -> some View {
        SectionTitleView(
            "Сводка дня",
            subtitle: "Цель, запланированный рацион и фактическое питание за текущий день."
        )

        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Дневная цель")
                        .font(.headline)

                    Spacer()

                    Text("\(goal.targetCalories) ккал")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    summaryTile(title: "Белки", value: "\(goal.proteinGrams) г")
                    summaryTile(title: "Жиры", value: "\(goal.fatGrams) г")
                    summaryTile(title: "Углеводы", value: "\(goal.carbsGrams) г")
                }
            }
        }

        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("План и факт")
                        .font(.headline)

                    Spacer()

                    if nutrientFocus != .none {
                        StatPill(text: nutrientFocus.displayName)
                    }
                }

                InfoValueRow(title: "План по калориям", value: "\(Int(plannedSummary.macros.calories.rounded())) ккал")
                InfoValueRow(title: "Факт по калориям", value: "\(Int(actualSummary.macros.calories.rounded())) ккал")

                Divider()

                HStack(spacing: 12) {
                    macroMiniCard(
                        title: "Белки",
                        planned: plannedSummary.macros.protein,
                        actual: actualSummary.macros.protein
                    )

                    macroMiniCard(
                        title: "Жиры",
                        planned: plannedSummary.macros.fat,
                        actual: actualSummary.macros.fat
                    )

                    macroMiniCard(
                        title: "Углеводы",
                        planned: plannedSummary.macros.carbs,
                        actual: actualSummary.macros.carbs
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func micronutrientsSection(
        plannedSummary: NutritionSummary,
        actualSummary: NutritionSummary,
        nutrientFocus: NutrientFocus
    ) -> some View {
        SectionTitleView(
            "Микронутриенты",
            subtitle: "План, факт и текущий приоритет по витаминам и минералам."
        )

        VStack(spacing: 12) {
            ForEach(NutrientCatalog.focusable) { nutrient in
                micronutrientCard(
                    nutrient: nutrient,
                    planned: plannedSummary.nutrients[nutrient.id, default: 0],
                    actual: actualSummary.nutrients[nutrient.id, default: 0],
                    isFocused: nutrientFocus.nutrientId == nutrient.id
                )
            }
        }
    }

    private var actionsSection: some View {
        Group {
            SectionTitleView(
                "Быстрые действия",
                subtitle: "Переход к основным сценариям текущего дня."
            )

            LazyVGrid(columns: actionColumns, spacing: 12) {
                NavigationLink {
                    DiaryView(vm: vm)
                } label: {
                    QuickActionTile(
                        systemImage: "book.pages",
                        title: "Дневник",
                        subtitle: "Записи за текущий день"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PlanComparisonView(vm: vm)
                } label: {
                    QuickActionTile(
                        systemImage: "chart.bar.xaxis",
                        title: "План и факт",
                        subtitle: "Сравнение за сегодня"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PlanHistoryView(vm: vm)
                } label: {
                    QuickActionTile(
                        systemImage: "clock.arrow.circlepath",
                        title: "История",
                        subtitle: "Прошлые дни и записи"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    CloudRestoreView(vm: vm)
                } label: {
                    QuickActionTile(
                        systemImage: "arrow.triangle.2.circlepath",
                        title: "Синхронизация",
                        subtitle: "Обновить сохранённые данные"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func mealsSection(nutrientFocus: NutrientFocus) -> some View {
        SectionTitleView(
            "Блюда на сегодня",
            subtitle: "Текущий набор блюд, подобранных на день."
        )

        if vm.dayPlan.meals.isEmpty {
            AppCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("План пока не сформирован")
                        .font(.headline)

                    Text("Перейди в раздел плана и собери рацион на день.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            VStack(spacing: 12) {
                ForEach(vm.dayPlan.meals) { meal in
                    NavigationLink {
                        RecipeDetailView(mealId: meal.id, vm: vm)
                    } label: {
                        mealCard(for: meal, nutrientFocus: nutrientFocus)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func micronutrientCard(
        nutrient: Nutrient,
        planned: Double,
        actual: Double,
        isFocused: Bool
    ) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(nutrient.name)
                        .font(.headline)

                    Spacer()

                    if isFocused {
                        StatPill(text: "Фокус")
                    }
                }

                InfoValueRow(title: "План", value: amountText(planned, nutrient: nutrient))
                InfoValueRow(title: "Факт", value: amountText(actual, nutrient: nutrient))

                if let target = nutrient.targetPerDay {
                    Divider()

                    InfoValueRow(title: "Ориентир", value: amountText(target, nutrient: nutrient))
                    InfoValueRow(title: "Покрытие", value: progressText(actual: actual, target: target))
                }
            }
        }
    }

    @ViewBuilder
    private func mealCard(
        for meal: PlannedMeal,
        nutrientFocus: NutrientFocus
    ) -> some View {
        let summary = vm.summary(for: meal.recipe)
        let focusedAmount = NutrientCatalog.focusedAmount(
            in: summary.nutrients,
            for: nutrientFocus
        )

        AppCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(meal.type.ruTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(vm.displayTitle(for: meal.recipe))
                        .font(.headline)
                        .multilineTextAlignment(.leading)

                    Text("Калории: \(Int(summary.macros.calories.rounded()))")
                        .font(.subheadline)

                    Text(
                        "Б: \(summary.macros.protein, specifier: "%.1f") Ж: \(summary.macros.fat, specifier: "%.1f") У: \(summary.macros.carbs, specifier: "%.1f")"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if nutrientFocus != .none,
                       let nutrient = NutrientCatalog.nutrient(for: nutrientFocus),
                       focusedAmount > 0 {
                        Text("\(nutrient.name): \(amountText(focusedAmount, nutrient: nutrient))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)

                    if vm.isMealLogged(meal.id) {
                        StatPill(text: "Добавлено")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func summaryTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }

    @ViewBuilder
    private func macroMiniCard(
        title: String,
        planned: Double,
        actual: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("План: \(planned, specifier: "%.1f")")
                .font(.caption)

            Text("Факт: \(actual, specifier: "%.1f")")
                .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }

    private func amountText(_ value: Double, nutrient: Nutrient) -> String {
        String(format: "%.1f %@", value, nutrient.unit)
    }

    private func progressText(actual: Double, target: Double) -> String {
        guard target > 0 else { return "—" }
        let progress = min(max(actual / target, 0), 9.99) * 100
        return String(format: "%.0f %%", progress)
    }
}
