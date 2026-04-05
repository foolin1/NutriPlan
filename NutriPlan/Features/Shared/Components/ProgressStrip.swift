import SwiftUI

struct ProgressStrip: View {
    let value: Double
    let maxValue: Double

    private var normalized: Double {
        guard maxValue > 0 else { return 0 }
        return min(max(value / maxValue, 0), 1)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.tertiarySystemFill))

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.85))
                    .frame(width: geometry.size.width * normalized)
            }
        }
        .frame(height: 10)
    }
}
