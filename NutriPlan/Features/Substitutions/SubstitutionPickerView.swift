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

                            Text("Candidates are ranked by nutritional closeness for the same ingredient weight.")
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

                                Text("Suitable alternatives were not found for the current restrictions and product set.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        SectionTitleView(
                            "Suggested replacements",
                            subtitle: "The higher the score, the closer the replacement is to the original nutritional profile."
                        )

                        VStack(spacing: 12) {
                            ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                                Button {
                                    onSelect(candidate)
                                    dismiss()
                                } label: {
                                    AppCard {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack(alignment: .top) {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(shorten(candidate.name))
                                                        .font(.headline)
                                                        .foregroundStyle(.primary)

                                                    Text(scoreDescription(for: candidate.score))
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                }

                                                Spacer()

                                                if index == 0 {
                                                    StatPill(text: "Best match")
                                                } else {
                                                    StatPill(text: scoreBadge(for: candidate.score))
                                                }
                                            }

                                            Divider()

                                            HStack(spacing: 16) {
                                                metricBlock(title: "Score", value: "\(Int(candidate.score.rounded())) / 100")
                                                metricBlock(title: "Penalty", value: String(format: "%.1f", candidate.weightedPenalty))
                                                metricBlock(title: "Tag bonus", value: String(format: "+%.1f", candidate.tagBonus))
                                            }

                                            HStack(spacing: 16) {
                                                metricBlock(title: "Δ kcal", value: formattedDelta(candidate.deltaMacros.calories))
                                                metricBlock(title: "Δ P", value: formattedDelta(candidate.deltaMacros.protein))
                                                metricBlock(title: "Δ F", value: formattedDelta(candidate.deltaMacros.fat))
                                                metricBlock(title: "Δ C", value: formattedDelta(candidate.deltaMacros.carbs))
                                            }

                                            if let ironDelta = candidate.ironDelta {
                                                Text("Δ iron: \(formattedDelta(ironDelta)) mg")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
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

    private func scoreBadge(for score: Double) -> String {
        switch score {
        case 90...:
            return "Very close"
        case 75..<90:
            return "Good match"
        default:
            return "Flexible"
        }
    }

    private func scoreDescription(for score: Double) -> String {
        switch score {
        case 90...:
            return "Very small nutritional deviation from the original ingredient."
        case 75..<90:
            return "Good nutritional match with moderate deviation."
        default:
            return "Usable alternative, but the nutritional deviation is more noticeable."
        }
    }

    @ViewBuilder
    private func metricBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
