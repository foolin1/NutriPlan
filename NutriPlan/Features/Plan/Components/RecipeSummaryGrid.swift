import SwiftUI

struct RecipeSummaryGrid: View {
    let caloriesText: String
    let proteinText: String
    let fatText: String
    let carbsText: String
    let ironText: String?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            metricTile(title: "Calories", value: caloriesText)
            metricTile(title: "Protein", value: proteinText)
            metricTile(title: "Fat", value: fatText)
            metricTile(title: "Carbs", value: carbsText)

            if let ironText {
                metricTile(title: "Iron", value: ironText)
            }
        }
    }

    @ViewBuilder
    private func metricTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }
}
