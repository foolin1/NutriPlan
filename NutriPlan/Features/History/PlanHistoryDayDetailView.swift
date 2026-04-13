import SwiftUI

struct PlanHistoryDayDetailView: View {
    @ObservedObject var vm: PlanViewModel
    let record: PlanHistoryRecord

    var body: some View {
        let planned = plannedSummary
        let actual = actualSummary
        let shoppingItems = shoppingList
        let checkedCount = shoppingItems.filter { record.checkedShoppingItemIds.contains($0.id) }.count
        let recommendation = archivedAdjustment

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                SectionTitleView(
                    "Сводка дня",
                    subtitle: "Краткое сравнение запланированного и фактического питания за выбранный день."
                )

                AppCard {
                    Text("План")
                        .font(.headline)

                    InfoValueRow(title: "Калории", value: "\(Int(planned.macros.calories)) ккал")
                    InfoValueRow(title: "Белки", value: String(format: "%.1f г", planned.macros.protein))
                    InfoValueRow(title: "Жиры", value: String(format: "%.1f г", planned.macros.fat))
                    InfoValueRow(title: "Углеводы", value: String(format: "%.1f г", planned.macros.carbs))
                }

                AppCard {
                    HStack {
                        Text("Факт")
                            .font(.headline)

                        Spacer()

                        if record.diaryDay.entries.isEmpty {
                            StatPill(text: "Нет записей")
                        }
                    }

                    if record.diaryDay.entries.isEmpty {
                        Text("По этому дню не было сохранено фактических записей питания.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        InfoValueRow(title: "Калории", value: "\(Int(actual.macros.calories)) ккал")
                        InfoValueRow(title: "Белки", value: String(format: "%.1f г", actual.macros.protein))
                        InfoValueRow(title: "Жиры", value: String(format: "%.1f г", actual.macros.fat))
                        InfoValueRow(title: "Углеводы", value: String(format: "%.1f г", actual.macros.carbs))
                    }
                }

                AppCard {
                    Text("Покупки")
                        .font(.headline)

                    if shoppingItems.isEmpty {
                        Text("Для этого дня список покупок не сформирован.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        InfoValueRow(title: "Всего позиций", value: "\(shoppingItems.count)")
                        InfoValueRow(title: "Отмечено как купленное", value: "\(checkedCount)")
                    }
                }

                if let recommendation {
                    SectionTitleView(
                        "Рекомендация, которая была бы дана на следующий день",
                        subtitle: "Эта сводка пересчитывается по сохранённому факту и помогает анализировать прошлые отклонения."
                    )

                    AppCard {
                        Text(recommendation.statusTitle)
                            .font(.headline)

                        Text(recommendation.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Divider()

                        InfoValueRow(title: "Калории", value: "\(recommendation.nextDayGoal.targetCalories) ккал")
                        InfoValueRow(title: "Белки", value: "\(recommendation.nextDayGoal.proteinGrams) г")
                        InfoValueRow(title: "Жиры", value: "\(recommendation.nextDayGoal.fatGrams) г")
                        InfoValueRow(title: "Углеводы", value: "\(recommendation.nextDayGoal.carbsGrams) г")

                        if !recommendation.hints.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Подсказки")
                                    .font(.subheadline.weight(.semibold))

                                ForEach(recommendation.hints, id: \.self) { hint in
                                    Text("• \(hint)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                SectionTitleView(
                    "План питания",
                    subtitle: "Блюда, которые были включены в план этого дня."
                )

                if record.dayPlan.meals.isEmpty {
                    emptyCard(text: "В архиве этого дня не сохранились блюда плана.")
                } else {
                    VStack(spacing: 12) {
                        ForEach(record.dayPlan.meals) { meal in
                            mealCard(for: meal)
                        }
                    }
                }

                SectionTitleView(
                    "Фактическое питание",
                    subtitle: "Блюда, которые были отмечены пользователем как реально съеденные."
                )

                if record.diaryDay.entries.isEmpty {
                    emptyCard(text: "Фактические записи по этому дню отсутствуют.")
                } else {
                    VStack(spacing: 12) {
                        ForEach(record.diaryDay.entries) { entry in
                            diaryEntryCard(for: entry)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(displayTitle(for: record.dayId))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var plannedSummary: NutritionSummary {
        summarize(recipes: record.dayPlan.meals.map(\.recipe))
    }

    private var actualSummary: NutritionSummary {
        summarize(recipes: record.diaryDay.entries.map(\.recipe))
    }

    private var shoppingList: [ShoppingItem] {
        ShoppingListBuilder.build(
            recipes: record.dayPlan.meals.map(\.recipe),
            foodsById: vm.foodsById
        )
    }

    private var archivedAdjustment: PlanAdjustment? {
        guard !record.diaryDay.entries.isEmpty else { return nil }
        guard let baseGoal = baseGoalFromSignature(record.inputSignature) else { return nil }

        return PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actualSummary
        )
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(displayTitle(for: record.dayId))
                    .font(.title2.weight(.bold))

                Text(displaySubtitle(for: record.dayId))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Просмотр сохранённого состояния дня в режиме истории.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func mealCard(for meal: PlannedMeal) -> some View {
        let summary = vm.summary(for: meal.recipe)

        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(meal.type.ruTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(vm.displayTitle(for: meal.recipe))
                    .font(.headline)

                Text("Калории: \(Int(summary.macros.calories))")
                    .font(.subheadline)

                Text(
                    "Б: \(summary.macros.protein, specifier: "%.1f") Ж: \(summary.macros.fat, specifier: "%.1f") У: \(summary.macros.carbs, specifier: "%.1f")"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func diaryEntryCard(for entry: ConsumedFoodEntry) -> some View {
        let summary = vm.summary(for: entry.recipe)

        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.mealType.ruTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(entry.title)
                    .font(.headline)

                Text("Калории: \(Int(summary.macros.calories))")
                    .font(.subheadline)

                Text(
                    "Б: \(summary.macros.protein, specifier: "%.1f") Ж: \(summary.macros.fat, specifier: "%.1f") У: \(summary.macros.carbs, specifier: "%.1f")"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func emptyCard(text: String) -> some View {
        AppCard {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func summarize(recipes: [Recipe]) -> NutritionSummary {
        var totalMacros = Macros.zero
        var totalNutrients: [String: Double] = [:]

        for recipe in recipes {
            let summary = vm.summary(for: recipe)
            totalMacros = totalMacros + summary.macros

            for (key, value) in summary.nutrients {
                totalNutrients[key, default: 0] += value
            }
        }

        return NutritionSummary(macros: totalMacros, nutrients: totalNutrients)
    }

    private func baseGoalFromSignature(_ signature: PlanInputSignature) -> NutritionGoal? {
        guard let calories = signature.targetCalories,
              let protein = signature.proteinGrams,
              let fat = signature.fatGrams,
              let carbs = signature.carbsGrams else {
            return nil
        }

        return NutritionGoal(
            targetCalories: calories,
            proteinGrams: protein,
            fatGrams: fat,
            carbsGrams: carbs
        )
    }

    private func displayTitle(for dayId: String) -> String {
        guard let date = Self.storageFormatter.date(from: dayId) else {
            return dayId
        }

        return Self.displayFormatter.string(from: date)
    }

    private func displaySubtitle(for dayId: String) -> String {
        guard let date = Self.storageFormatter.date(from: dayId) else {
            return "Архивная запись"
        }

        return Self.weekdayFormatter.string(from: date)
    }

    private static let storageFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}
