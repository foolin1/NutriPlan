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
                    "Energy and macros",
                    subtitle: "Compare the planned nutrition with the meals actually added to the diary."
                )

                ComparisonMetricCard(metric: comparison.calories)
                ComparisonMetricCard(metric: comparison.protein)
                ComparisonMetricCard(metric: comparison.fat)
                ComparisonMetricCard(metric: comparison.carbs)

                if let iron = comparison.iron {
                    SectionTitleView(
                        "Micronutrient comparison",
                        subtitle: "Additional micronutrient check for the current day."
                    )

                    ComparisonMetricCard(metric: iron)
                }

                if let adjustment {
                    SectionTitleView(
                        "Tomorrow recommendation",
                        subtitle: "The next day target adapts to the current deviation."
                    )

                    AppCard {
                        Text(adjustment.statusTitle)
                            .font(.headline)

                        Text(adjustment.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Divider()

                        InfoValueRow(title: "Calories", value: "\(adjustment.nextDayGoal.targetCalories) kcal")
                        InfoValueRow(title: "Protein", value: "\(adjustment.nextDayGoal.proteinGrams) g")
                        InfoValueRow(title: "Fat", value: "\(adjustment.nextDayGoal.fatGrams) g")
                        InfoValueRow(title: "Carbs", value: "\(adjustment.nextDayGoal.carbsGrams) g")

                        if !adjustment.hints.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Hints")
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
        .navigationTitle("Plan vs Actual")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func headerCard(for comparison: PlanComparison) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily comparison")
                    .font(.title2.weight(.bold))

                Text(overallStatus(for: comparison))
                    .font(.headline)

                Text("This screen shows how close the actual intake is to the planned daily nutrition target.")
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
            return "You are close to the planned nutrition targets."
        } else {
            return "There is a noticeable difference between the plan and the actual intake."
        }
    }
}
