import SwiftUI

struct RecipeIngredientCard: View {
    let title: String
    let gramsText: String
    let caloriesText: String
    let proteinText: String
    let fatText: String
    let carbsText: String
    let ironText: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        Text(gramsText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 8) {
                        StatPill(text: "Заменить")
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider()

                HStack(spacing: 16) {
                    nutrientMiniBlock(title: "ккал", value: caloriesText)
                    nutrientMiniBlock(title: "Б", value: proteinText)
                    nutrientMiniBlock(title: "Ж", value: fatText)
                    nutrientMiniBlock(title: "У", value: carbsText)
                }

                if let ironText {
                    Text("Железо: \(ironText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func nutrientMiniBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
