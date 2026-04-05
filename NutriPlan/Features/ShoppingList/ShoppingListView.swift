import SwiftUI

struct ShoppingListView: View {

    let items: [ShoppingItem]

    @AppStorage("shopping.checkedIds") private var checkedIdsString: String = ""

    var body: some View {
        List {
            ForEach(categoryKeysInUse, id: \.self) { categoryKey in
                if let categoryItems = grouped[categoryKey] {
                    Section(categoryTitle(for: categoryKey)) {
                        ForEach(categoryItems) { item in
                            row(for: item)
                        }
                    }
                }
            }
        }
        .navigationTitle("Shopping List")
        .toolbar {
            Button("Clear bought") {
                clearBought()
            }
        }
    }

    private var grouped: [String: [ShoppingItem]] {
        Dictionary(grouping: items, by: \.categoryKey)
    }

    private var categoryKeysInUse: [String] {
        let order = [
            "category.meat",
            "category.grain",
            "category.vegetable",
            "category.other"
        ]
        return order.filter { grouped[$0] != nil }
    }

    private func categoryTitle(for key: String) -> String {
        switch key {
        case "category.meat":
            return "Meat"
        case "category.grain":
            return "Grains"
        case "category.vegetable":
            return "Vegetables"
        default:
            return "Other"
        }
    }

    private var checkedIds: Set<String> {
        let parts = checkedIdsString.split(separator: ",").map(String.init)
        return Set(parts.filter { !$0.isEmpty })
    }

    private func saveCheckedIds(_ set: Set<String>) {
        checkedIdsString = set.sorted().joined(separator: ",")
    }

    private func toggleChecked(_ id: String) {
        var set = checkedIds
        if set.contains(id) {
            set.remove(id)
        } else {
            set.insert(id)
        }
        saveCheckedIds(set)
    }

    private func clearBought() {
        checkedIdsString = ""
    }

    @ViewBuilder
    private func row(for item: ShoppingItem) -> some View {
        let isChecked = checkedIds.contains(item.id)

        Button {
            toggleChecked(item.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)

                Text(item.name)

                Spacer()

                Text(formattedWeight(item.grams))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isChecked ? 0.55 : 1.0)
    }

    private func formattedWeight(_ grams: Double) -> String {
        let measurement: Measurement<UnitMass> =
            grams >= 1000
            ? Measurement(value: grams / 1000.0, unit: .kilograms)
            : Measurement(value: grams, unit: .grams)

        return measurement.formatted(.measurement(width: .abbreviated))
    }
}
