import SwiftUI

struct ShoppingItemRow: View {
    let item: ShoppingItem
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(isChecked ? Color.accentColor : Color.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .strikethrough(isChecked, color: .secondary)

                    Text(formattedWeight(item.grams))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isChecked {
                    StatPill(text: "Куплено")
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isChecked ? 0.72 : 1.0)
    }

    private func formattedWeight(_ grams: Double) -> String {
        let measurement: Measurement<UnitMass> =
            grams >= 1000
            ? Measurement(value: grams / 1000.0, unit: .kilograms)
            : Measurement(value: grams, unit: .grams)

        return measurement.formatted(.measurement(width: .abbreviated))
    }
}
