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
                            Text("Замена ингредиента")
                                .font(.title2.weight(.bold))

                            Text("Выбери наиболее подходящую замену для этого ингредиента.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Divider()

                            InfoValueRow(title: "Исходный ингредиент", value: shorten(originalName))
                            InfoValueRow(title: "Вес", value: "\(Int(grams)) г")
                        }
                    }

                    if candidates.isEmpty {
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Замены не найдены")
                                    .font(.headline)

                                Text("Для текущих ограничений и набора продуктов подходящих альтернатив не найдено.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        SectionTitleView(
                            "Подходящие варианты",
                            subtitle: "Сверху показаны самые близкие замены."
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

                                                    Text(matchDescription(for: candidate.score))
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                }

                                                Spacer()

                                                if index == 0 {
                                                    StatPill(text: "Лучшая замена")
                                                } else {
                                                    StatPill(text: matchLabel(for: candidate.score))
                                                }
                                            }

                                            Divider()

                                            HStack(spacing: 16) {
                                                metricBlock(title: "Калории", value: deltaValue(candidate.deltaMacros.calories))
                                                metricBlock(title: "Белки", value: deltaValue(candidate.deltaMacros.protein))
                                                metricBlock(title: "Жиры", value: deltaValue(candidate.deltaMacros.fat))
                                                metricBlock(title: "Углеводы", value: deltaValue(candidate.deltaMacros.carbs))
                                            }

                                            if let ironDelta = candidate.ironDelta {
                                                Text(ironDeltaDescription(ironDelta))
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
            .navigationTitle("Замена")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") {
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

    private func matchLabel(for score: Double) -> String {
        switch score {
        case 90...:
            return "Очень близко"
        case 75..<90:
            return "Хороший вариант"
        default:
            return "Допустимо"
        }
    }

    private func matchDescription(for score: Double) -> String {
        switch score {
        case 90...:
            return "Эта замена очень близка по пищевой ценности."
        case 75..<90:
            return "Эта замена хорошо подходит и сохраняет общий баланс блюда."
        default:
            return "Эту замену можно использовать, но отклонение будет заметнее."
        }
    }

    private func deltaValue(_ value: Double) -> String {
        if abs(value) < 0.05 {
            return "Без изменений"
        } else if value > 0 {
            return String(format: "+%.1f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }

    private func ironDeltaDescription(_ value: Double) -> String {
        if abs(value) < 0.05 {
            return "Содержание железа практически не изменится."
        } else if value > 0 {
            return String(format: "Железа станет немного больше: +%.2f мг.", value)
        } else {
            return String(format: "Железа станет немного меньше: %.2f мг.", value)
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
