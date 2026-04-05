import SwiftUI

struct DiaryEntryCard: View {
    let title: String
    let mealType: String
    let caloriesText: String
    let proteinText: String
    let fatText: String
    let carbsText: String
    let ironText: String?
    let onDelete: () -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.headline)

                        StatPill(text: mealType)
                    }

                    Spacer()

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.headline)
                    }
                }

                HStack(spacing: 16) {
                    nutrientBlock(title: "Calories", value: caloriesText)
                    nutrientBlock(title: "Protein", value: proteinText)
                }

                HStack(spacing: 16) {
                    nutrientBlock(title: "Fat", value: fatText)
                    nutrientBlock(title: "Carbs", value: carbsText)
                }

                if let ironText {
                    Text("Iron: \(ironText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func nutrientBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
