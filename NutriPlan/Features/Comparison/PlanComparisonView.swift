import SwiftUI

struct PlanComparisonView: View {
    @ObservedObject var vm: PlanViewModel
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let comparison = vm.comparison()
        let adjustment = vm.adjustmentRecommendation()
        let plannedSummary = vm.daySummary()
        let actualSummary = vm.actualSummary()
        let selectedFocus = appState.userProfile?.nutrientFocus ?? .none

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard(for: comparison)

                SectionTitleView(
                    "Сравнение плана и факта",
                    subtitle: "Посмотри, насколько фактическое питание за день близко к запланированным показателям."
                )

                metricCard(for: comparison.calories)
                metricCard(for: comparison.protein)
                metricCard(for: comparison.fat)
                metricCard(for: comparison.carbs)

                SectionTitleView(
                    "Микронутриенты",
                    subtitle: "Здесь можно сравнить план, факт и ориентировочную суточную норму по ключевым витаминам и минералам."
                )

                VStack(spacing: 12) {
                    ForEach(NutrientCatalog.focusable) { nutrient in
                        micronutrientCard(
                            nutrient: nutrient,
                            planned: plannedSummary.nutrients[nutrient.id, default: 0],
                            actual: actualSummary.nutrients[nutrient.id, default: 0],
                            isFocused: selectedFocus.nutrientId == nutrient.id
                        )
                    }
                }

                if let adjustment {
                    SectionTitleView(
                        "Рекомендация на следующий день",
                        subtitle: "Следующая цель корректируется мягко и без резких ограничений."
                    )

                    AppCard {
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
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("План и факт")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func headerCard(for comparison: PlanComparison) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Сравнение за день")
                    .font(.title2.weight(.bold))

                Text(overallStatus(for: comparison))
                    .font(.headline)

                Text("Этот экран показывает, насколько фактическое питание за день совпадает с планом по макронутриентам и ключевым витаминам и минералам.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func metricCard(for metric: PlanComparisonMetric) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(localizedTitle(metric.title))
                        .font(.headline)

                    Spacer()

                    StatPill(text: deltaText(for: metric))
                }

                Text(statusText(for: metric))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                InfoValueRow(title: "План", value: valueText(metric.planned, unit: metric.unit))
                InfoValueRow(title: "Факт", value: valueText(metric.actual, unit: metric.unit))
                InfoValueRow(title: "Отклонение", value: deltaText(for: metric))
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
        let delta = actual - planned

        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(nutrient.name)
                        .font(.headline)

                    Spacer()

                    if isFocused {
                        StatPill(text: "Выбранный фокус")
                    } else {
                        StatPill(text: deltaText(delta, unit: nutrient.unit))
                    }
                }

                Text(micronutrientStatusText(delta: delta))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                InfoValueRow(title: "План", value: amountText(planned, nutrient: nutrient))
                InfoValueRow(title: "Факт", value: amountText(actual, nutrient: nutrient))
                InfoValueRow(title: "Отклонение", value: deltaText(delta, unit: nutrient.unit))

                if let target = nutrient.targetPerDay {
                    Divider()
                    InfoValueRow(title: "Ориентир", value: amountText(target, nutrient: nutrient))
                    InfoValueRow(title: "Покрытие по факту", value: progressText(actual: actual, target: target))
                }
            }
        }
    }

    private func overallStatus(for comparison: PlanComparison) -> String {
        let caloriesClose = abs(comparison.calories.delta) <= 150
        let proteinClose = abs(comparison.protein.delta) <= 15
        let fatClose = abs(comparison.fat.delta) <= 10
        let carbsClose = abs(comparison.carbs.delta) <= 20

        if caloriesClose && proteinClose && fatClose && carbsClose {
            return "Фактическое питание близко к запланированным целям."
        } else {
            return "Между планом и фактическим питанием есть заметное различие."
        }
    }

    private func statusText(for metric: PlanComparisonMetric) -> String {
        let delta = metric.delta

        switch metric.unit {
        case "kcal":
            if abs(delta) <= 100 {
                return "Показатель очень близок к плану."
            } else if delta < 0 {
                return "Фактическое значение ниже запланированного."
            } else {
                return "Фактическое значение выше запланированного."
            }

        case "g":
            if abs(delta) <= 8 {
                return "Показатель очень близок к плану."
            } else if delta < 0 {
                return "Фактическое значение ниже запланированного."
            } else {
                return "Фактическое значение выше запланированного."
            }

        case "mg":
            return micronutrientStatusText(delta: delta)

        default:
            return "Сравнение показателя с планом."
        }
    }

    private func micronutrientStatusText(delta: Double) -> String {
        if abs(delta) <= 0.5 {
            return "Показатель очень близок к плану."
        } else if delta < 0 {
            return "Фактическое значение ниже запланированного."
        } else {
            return "Фактическое значение выше запланированного."
        }
    }

    private func localizedTitle(_ title: String) -> String {
        switch title.lowercased() {
        case "calories":
            return "Калории"
        case "protein":
            return "Белки"
        case "fat":
            return "Жиры"
        case "carbs":
            return "Углеводы"
        case "iron":
            return "Железо"
        default:
            return title
        }
    }

    private func localizedUnit(_ unit: String) -> String {
        switch unit {
        case "kcal":
            return "ккал"
        case "g":
            return "г"
        case "mg":
            return "мг"
        default:
            return unit
        }
    }

    private func valueText(_ value: Double, unit: String) -> String {
        if unit == "kcal" {
            return "\(Int(value.rounded())) \(localizedUnit(unit))"
        } else {
            return String(format: "%.1f %@", value, localizedUnit(unit))
        }
    }

    private func deltaText(for metric: PlanComparisonMetric) -> String {
        deltaText(metric.delta, unit: metric.unit)
    }

    private func deltaText(_ value: Double, unit: String) -> String {
        if unit == "kcal" {
            return String(format: "%+.0f %@", value, localizedUnit(unit))
        } else {
            return String(format: "%+.1f %@", value, localizedUnit(unit))
        }
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
