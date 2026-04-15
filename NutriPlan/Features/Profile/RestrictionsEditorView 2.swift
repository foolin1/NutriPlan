import SwiftUI

struct RestrictionsEditorView: View {
    @Binding var allergensText: String
    @Binding var excludedProductsText: String

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ограничения")
                        .font(.headline)

                    Text("Здесь можно указать аллергенные продукты и конкретные продукты, которые не хочется видеть в плане. Значения вводятся через запятую.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Аллергены") {
                TextField("Например: орехи, рыба, молоко", text: $allergensText)

                parsedPreviewSection(
                    title: "Будут учтены как аллергены",
                    items: parsedList(from: allergensText)
                )
            }

            Section("Продукты, которые не хочу видеть в плане") {
                TextField("Например: брокколи, авокадо, киноа", text: $excludedProductsText)

                parsedPreviewSection(
                    title: "Будут исключены из плана и замен",
                    items: parsedList(from: excludedProductsText)
                )
            }

            Section("Подсказка") {
                Text("Лучше указывать названия кратко и без лишних пояснений. Например: «орехи, креветки» или «творог, брокколи».")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ограничения")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func parsedPreviewSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if items.isEmpty {
                Text("Пока ничего не указано")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                FlexibleChipsView(items: items)
            }
        }
        .padding(.vertical, 4)
    }

    private func parsedList(from text: String) -> [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct FlexibleChipsView: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunked(items, size: 3), id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        RestrictionChip(title: item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func chunked(_ items: [String], size: Int) -> [[String]] {
        stride(from: 0, to: items.count, by: size).map {
            Array(items[$0..<min($0 + size, items.count)])
        }
    }
}

private struct RestrictionChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
    }
}
