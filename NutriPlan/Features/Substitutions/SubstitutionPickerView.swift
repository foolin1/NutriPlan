import SwiftUI

struct SubstitutionPickerView: View {
    let originalName: String
    let grams: Double
    let candidates: [SubstitutionCandidate]
    let onSelect: (SubstitutionCandidate) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AppCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Replace ingredient")
                                .font(.title2.weight(.bold))

                            Text("Choose an alternative with close nutritional values for the same ingredient weight.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Divider()

                            InfoValueRow(title: "Original ingredient", value: shorten(originalName))
                            InfoValueRow(title: "Weight", value: "\(Int(grams)) g")
                        }
                    }

                    if candidates.isEmpty {
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("No substitutions found")
                                    .font(.headline)

                                Text("Try another ingredient. Suitable alternatives were not found for the current restrictions and product set.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        SectionTitleView(
                            "Suggested replacements",
                            subtitle: "Candidates are sorted by closeness to the original nutritional profile."
                        )

                        VStack(spacing: 12) {
                            ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                                SubstitutionCandidateCard(
                                    name: shorten(candidate.name),
                                    matchLabel: matchLabel(for: candidate.deltaMacros),
                                    matchDescription: matchDescription(for: candidate.deltaMacros),
                                    caloriesDelta: formattedDelta(candidate.deltaMacros.calories),
                                    proteinDelta: formattedDelta(candidate.deltaMacros.protein),
                                    fatDelta: formattedDelta(candidate.deltaMacros.fat),
                                    carbsDelta: formattedDelta(candidate.deltaMacros.carbs),
                                    isBest: index == 0
                                ) {
                                    onSelect(candidate)
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Substitution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func shorten(_ name: String) -> String {
        let result = name.replacingOccurrences(
            of: #"\s*\([^)]*\)"#,
            with: "",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formattedDelta(_ value: Double) -> String {
        String(format: "%+.1f", value)
    }

    private func matchLabel(for delta: Macros) -> String {
        let score = closenessScore(for: delta)

        switch score {
        case 0..<25:
            return "Best"
        case 25..<60:
            return "Close"
        default:
            return "Flexible"
        }
    }

    private func matchDescription(for delta: Macros) -> String {
        let score = closenessScore(for: delta)

        switch score {
        case 0..<25:
            return "Very close nutritional match to the original ingredient."
        case 25..<60:
            return "Good replacement with small nutritional deviation."
        default:
            return "Usable alternative, but nutritional values differ more noticeably."
        }
    }

    private func closenessScore(for delta: Macros) -> Double {
        abs(delta.calories) * 0.4
        + abs(delta.protein) * 4.0
        + abs(delta.fat) * 3.0
        + abs(delta.carbs) * 2.0
    }
}
