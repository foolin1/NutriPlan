import SwiftUI

struct ComparisonMetricCard: View {
    let metric: PlanComparisonMetric

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metric.title)
                            .font(.headline)

                        Text(statusText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    StatPill(text: deltaText)
                }

                ProgressStrip(
                    value: metric.actual,
                    maxValue: max(metric.planned, metric.actual, 1)
                )

                HStack(spacing: 12) {
                    valueBlock(
                        title: "Planned",
                        value: valueText(metric.planned)
                    )

                    valueBlock(
                        title: "Actual",
                        value: valueText(metric.actual)
                    )

                    valueBlock(
                        title: "Completion",
                        value: String(format: "%.0f%%", metric.completionPercent)
                    )
                }
            }
        }
    }

    private var deltaText: String {
        if metric.unit == "kcal" {
            return String(format: "%+.0f %@", metric.delta, metric.unit)
        }

        return String(format: "%+.1f %@", metric.delta, metric.unit)
    }

    private var statusText: String {
        let absoluteDelta = abs(metric.delta)

        switch metric.unit {
        case "kcal":
            if absoluteDelta <= 100 { return "Very close to plan" }
            if absoluteDelta <= 250 { return "Moderate deviation" }
            return "Large deviation"
        case "g":
            if absoluteDelta <= 8 { return "Very close to plan" }
            if absoluteDelta <= 18 { return "Moderate deviation" }
            return "Large deviation"
        case "mg":
            if absoluteDelta <= 0.5 { return "Very close to plan" }
            if absoluteDelta <= 1.5 { return "Moderate deviation" }
            return "Large deviation"
        default:
            return "Comparison"
        }
    }

    private func valueText(_ value: Double) -> String {
        if metric.unit == "kcal" {
            return "\(Int(value.rounded())) \(metric.unit)"
        }

        return String(format: "%.1f %@", value, metric.unit)
    }

    @ViewBuilder
    private func valueBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }
}
