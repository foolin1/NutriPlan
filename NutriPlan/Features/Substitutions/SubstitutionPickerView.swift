import SwiftUI

struct SubstitutionPickerView: View {
    let originalName: String
    let grams: Double
    let candidates: [SubstitutionCandidate]
    let onSelect: (SubstitutionCandidate) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("\(shorten(originalName)) • \(Int(grams)) g")
                }

                if candidates.isEmpty {
                    Text("No substitutions found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(candidates) { c in
                        Button {
                            onSelect(c)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(shorten(c.name))
                                    .font(.headline)

                                Text(deltaText(c.deltaMacros))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Replace ingredient")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func shorten(_ name: String) -> String {
        // "Quinoa (cooked)" -> "Quinoa"
        let result = name.replacingOccurrences(
            of: #"\s*\([^)]*\)"#,
            with: "",
            options: .regularExpression
        )
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func deltaText(_ d: Macros) -> String {
        // %+0.1f сразу ставит знак +/-
        func fmt(_ v: Double) -> String { String(format: "%+.1f", v) }

        return "Δ kcal \(fmt(d.calories)) • P \(fmt(d.protein)) • F \(fmt(d.fat)) • C \(fmt(d.carbs))"
    }
}
