import SwiftUI

struct SubstitutionCandidateCard: View {
    let name: String
    let matchLabel: String
    let matchDescription: String
    let caloriesDelta: String
    let proteinDelta: String
    let fatDelta: String
    let carbsDelta: String
    let isBest: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        Text(matchDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 8) {
                        if isBest {
                            StatPill(text: "Лучшая замена")
                        } else {
                            StatPill(text: matchLabel)
                        }

                        Image(systemName: "checkmark.circle")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }
                }

                Divider()

                HStack(spacing: 16) {
                    deltaBlock(title: "Δ ккал", value: caloriesDelta)
                    deltaBlock(title: "Δ Б", value: proteinDelta)
                    deltaBlock(title: "Δ Ж", value: fatDelta)
                    deltaBlock(title: "Δ У", value: carbsDelta)
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
    private func deltaBlock(title: String, value: String) -> some View {
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
