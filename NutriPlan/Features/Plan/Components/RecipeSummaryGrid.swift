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
            metricTile(title: "Калории", value: caloriesText)
            metricTile(title: "Белки", value: proteinText)
            metricTile(title: "Жиры", value: fatText)
            metricTile(title: "Углеводы", value: carbsText)

            if let ironText {
                metricTile(title: "Железо", value: ironText)
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
