import SwiftUI

struct IngredientPortionControl: View {
    let grams: Double
    let step: Double
    let canDecrease: Bool
    let canIncrease: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("Portion")
                .font(.subheadline.weight(.medium))

            Spacer()

            Button(action: onDecrease) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
            }
            .disabled(!canDecrease)

            Text("\(Int(grams)) g")
                .font(.subheadline.weight(.semibold))
                .frame(minWidth: 70)

            Button(action: onIncrease) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .disabled(!canIncrease)

            StatPill(text: "Step \(Int(step)) g")
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
    }
}
