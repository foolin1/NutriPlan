import SwiftUI

struct PlanComparisonView: View {

    @ObservedObject var vm: PlanViewModel

    var body: some View {
        let comparison = vm.comparison()
        let adjustment = vm.adjustmentRecommendation()

        List {
            Section("Overview") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(overallStatus(for: comparison))
                        .font(.headline)

                    Text("This screen compares your planned daily nutrition with the meals you actually added to the diary.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Energy and macros") {
                ComparisonMetricRow(metric: comparison.calories)
                ComparisonMetricRow(metric: comparison.protein)
                ComparisonMetricRow(metric: comparison.fat)
                ComparisonMetricRow(metric: comparison.carbs)
            }

            if let iron = comparison.iron {
                Section("Micronutrients") {
                    ComparisonMetricRow(metric: iron)
                }
            }

            if let adjustment {
                Section("Tomorrow recommendation") {
                    Text(adjustment.statusTitle)
                        .font(.headline)

                    Text(adjustment.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ComparisonGoalRow(title: "Calories", value: "\(adjustment.nextDayGoal.targetCalories) kcal")
                    ComparisonGoalRow(title: "Protein", value: "\(adjustment.nextDayGoal.proteinGrams) g")
                    ComparisonGoalRow(title: "Fat", value: "\(adjustment.nextDayGoal.fatGrams) g")
                    ComparisonGoalRow(title: "Carbs", value: "\(adjustment.nextDayGoal.carbsGrams) g")

                    if !adjustment.hints.isEmpty {
                        ForEach(adjustment.hints, id: \.self) { hint in
                            Text("• \(hint)")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Plan vs Actual")
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

private struct ComparisonMetricRow: View {
    let metric: PlanComparisonMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(metric.title)
                    .font(.headline)
                Spacer()
                Text(deltaText(metric.delta, unit: metric.unit))
                    .font(.subheadline)
                    .foregroundStyle(deltaColor(metric.delta))
            }

            HStack {
                metricValueColumn(title: "Planned", value: metric.planned, unit: metric.unit)
                Spacer()
                metricValueColumn(title: "Actual", value: metric.actual, unit: metric.unit)
                Spacer()
                metricValueColumn(title: "Completion", value: metric.completionPercent, unit: "%")
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func metricValueColumn(title: String, value: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(valueText(value, unit: unit))
                .font(.subheadline)
        }
    }

    private func valueText(_ value: Double, unit: String) -> String {
        if unit == "%" {
            return String(format: "%.0f%%", value)
        } else if unit == "kcal" {
            return "\(Int(value.rounded())) \(unit)"
        } else {
            return String(format: "%.1f %@", value, unit)
        }
    }

    private func deltaText(_ delta: Double, unit: String) -> String {
        if unit == "kcal" {
            return String(format: "%+.0f %@", delta, unit)
        } else {
            return String(format: "%+.1f %@", delta, unit)
        }
    }

    private func deltaColor(_ delta: Double) -> Color {
        if abs(delta) < 0.01 {
            return .secondary
        }
        return delta > 0 ? .orange : .blue
    }
}

private struct ComparisonGoalRow: View {
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
