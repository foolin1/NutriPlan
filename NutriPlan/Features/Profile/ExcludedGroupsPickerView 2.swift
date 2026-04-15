import SwiftUI

struct ExcludedGroupsPickerView: View {
    @Binding var selection: Set<String>

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Исключаемые группы продуктов")
                        .font(.headline)

                    Text("Выбери группы продуктов, которые не должны попадать в план. Это помогает быстрее настроить рацион, чем перечислять каждый продукт вручную.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if selection.isEmpty {
                        Text("Сейчас ничего не исключено.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectionSummaryItems, id: \.self) { item in
                                    SelectionChip(title: item)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Категории") {
                ForEach(FoodGroupCatalog.all) { option in
                    Toggle(isOn: binding(for: option.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.title)

                            Text(option.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !selection.isEmpty {
                Section {
                    Button(role: .destructive) {
                        selection.removeAll()
                    } label: {
                        Text("Очистить выбранные группы")
                    }
                }
            }
        }
        .navigationTitle("Группы продуктов")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectionSummaryItems: [String] {
        selection
            .sorted()
            .map { FoodGroupCatalog.title(for: $0) }
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { selection.contains(id) },
            set: { isOn in
                if isOn {
                    selection.insert(id)
                } else {
                    selection.remove(id)
                }
            }
        )
    }
}

private struct SelectionChip: View {
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
