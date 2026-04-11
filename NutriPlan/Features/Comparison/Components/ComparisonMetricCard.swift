import SwiftUI

struct ComparisonMetricCard: View {
    let metric: PlanComparisonMetric

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizedMetricTitle(metric.title))
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
                        title: "План",
                        value: valueText(metric.planned)
                    )

                    valueBlock(
                        title: "Факт",
                        value: valueText(metric.actual)
                    )

                    valueBlock(
                        title: "Выполнение",
                        value: String(format: "%.0f%%", metric.completionPercent)
                    )
                }
            }
        }
    }

    private var deltaText: String {
        if metric.unit == "kcal" {
            return String(format: "%+.0f %@", metric.delta, localizedUnit(metric.unit))
        }

        return String(format: "%+.1f %@", metric.delta, localizedUnit(metric.unit))
    }

    private var statusText: String {
        let absoluteDelta = abs(metric.delta)

        switch metric.unit {
        case "kcal":
            if absoluteDelta <= 100 { return "Очень близко к плану" }
            if absoluteDelta <= 250 { return "Умеренное отклонение" }
            return "Сильное отклонение"
        case "g":
            if absoluteDelta <= 8 { return "Очень близко к плану" }
            if absoluteDelta <= 18 { return "Умеренное отклонение" }
            return "Сильное отклонение"
        case "mg":
            if absoluteDelta <= 0.5 { return "Очень близко к плану" }
            if absoluteDelta <= 1.5 { return "Умеренное отклонение" }
            return "Сильное отклонение"
        default:
            return "Сравнение"
        }
    }

    private func valueText(_ value: Double) -> String {
        if metric.unit == "kcal" {
            return "\(Int(value.rounded())) \(localizedUnit(metric.unit))"
        }

        return String(format: "%.1f %@", value, localizedUnit(metric.unit))
    }

    private func localizedMetricTitle(_ title: String) -> String {
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
