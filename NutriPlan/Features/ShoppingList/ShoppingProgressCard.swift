import SwiftUI

struct ShoppingProgressCard: View {
    let totalCount: Int
    let boughtCount: Int
    let remainingCount: Int

    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(boughtCount) / Double(totalCount)
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Прогресс покупок")
                            .font(.headline)

                        Text(progressDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemFill), lineWidth: 8)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                Color.accentColor,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(progress * 100))%")
                            .font(.caption.weight(.semibold))
                    }
                    .frame(width: 58, height: 58)
                }

                HStack(spacing: 12) {
                    summaryTile(title: "Всего", value: "\(totalCount)")
                    summaryTile(title: "Куплено", value: "\(boughtCount)")
                    summaryTile(title: "Осталось", value: "\(remainingCount)")
                }
            }
        }
    }

    private var progressDescription: String {
        if totalCount == 0 {
            return "Список появится после формирования плана."
        }

        if remainingCount == 0 {
            return "Все продукты из списка уже отмечены как купленные."
        }

        return "Отмечай купленные позиции и контролируй, что ещё осталось взять."
    }

    @ViewBuilder
    private func summaryTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }
}
