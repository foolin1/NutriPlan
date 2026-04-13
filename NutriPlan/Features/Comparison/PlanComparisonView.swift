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
                    "Сравнение плана и факта",
                    subtitle: "Посмотри, насколько фактическое питание за день близко к запланированным показателям."
                )

                ComparisonMetricCard(metric: comparison.calories)
                ComparisonMetricCard(metric: comparison.protein)
                ComparisonMetricCard(metric: comparison.fat)
                ComparisonMetricCard(metric: comparison.carbs)

                if let iron = comparison.iron {
                    SectionTitleView(
                        "Проверка микронутриента",
                        subtitle: "Дополнительное сравнение по железу для текущего дня."
                    )

                    ComparisonMetricCard(metric: iron)
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

                Text("Этот экран показывает, насколько фактическое питание за день совпадает с планом.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func overallStatus(for comparison: PlanComparison) -> String {
        let caloriesClose = abs(comparison.calories.delta) <= 150
        let proteinClose = abs(comparison.protein.delta) <= 15
        let fatClose = abs(comparison.fat.delta) <= 10
        let carbsClose = abs(comparison.carbs.delta) <= 20

        if caloriesClose && proteinClose && fatClose && carbsClose {
            return "Фактическое питание близко к целевым показателям."
        } else {
            return "Есть заметное отличие между планом и фактическим питанием."
        }
    }
}
