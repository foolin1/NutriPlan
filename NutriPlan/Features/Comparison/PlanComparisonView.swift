import SwiftUI

struct PlanComparisonView: View {
    @ObservedObject var vm: PlanViewModel

    var body: some View {
        let comparison = vm.comparison()
        let adjustment = vm.adjustmentRecommendation()

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard(for: comparison)

                SectionTitleView(
                    "Сравнение за день",
                    subtitle: "Здесь видно, насколько фактическое питание отличается от запланированного."
                )

                metricCard(for: comparison.calories)
                metricCard(for: comparison.protein)
                metricCard(for: comparison.fat)
                metricCard(for: comparison.carbs)

                if let iron = comparison.iron {
                    SectionTitleView(
                        "Дополнительно",
                        subtitle: "Дополнительная проверка по выбранному микронутриенту."
                    )

                    metricCard(for: iron)
                }

                if let adjustment {
                    SectionTitleView(
                        "Рекомендация на завтра",
                        subtitle: "Следующая цель может быть скорректирована по итогам текущего дня."
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
        .navigationTitle("План vs факт")
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

                Text("Экран помогает понять, где ты близок к цели, а где есть заметные отклонения.")
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

                InfoValueRow(
                    title: "План",
                    value: valueText(metric.planned, unit: metric.unit)
                )
                InfoValueRow(
                    title: "Факт",
                    value: valueText(metric.actual, unit: metric.unit)
                )
                InfoValueRow(
                    title: "Отклонение",
                    value: deltaText(for: metric)
                )
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
            if abs(delta) <= 0.5 {
                return "Показатель очень близок к плану."
            } else if delta < 0 {
                return "Фактическое значение ниже желаемого."
            } else {
                return "Фактическое значение выше желаемого."
            }
        default:
            return "Сравнение показателя с планом."
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
        if metric.unit == "kcal" {
            return String(format: "%+.0f %@", metric.delta, localizedUnit(metric.unit))
        } else {
            return String(format: "%+.1f %@", metric.delta, localizedUnit(metric.unit))
        }
    }
}
