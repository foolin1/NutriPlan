import SwiftUI

struct ShoppingListView: View {
    let items: [ShoppingItem]

    @AppStorage("shopping.checkedIds")
    private var checkedIdsString: String = ""

    @State private var searchText: String = ""
    @State private var filter: ShoppingFilter = .all

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                if items.isEmpty {
                    emptyPlanState
                } else {
                    ShoppingProgressCard(
                        totalCount: items.count,
                        boughtCount: boughtItems.count,
                        remainingCount: remainingItems.count
                    )

                    SectionTitleView(
                        "Filter",
                        subtitle: "Search items or switch between all, pending and bought products."
                    )

                    AppCard {
                        Picker("Filter", selection: $filter) {
                            ForEach(ShoppingFilter.allCases) { value in
                                Text(value.rawValue).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    SectionTitleView(
                        "Shopping list",
                        subtitle: "Items are grouped by category and aggregated from the current meal plan."
                    )

                    if filteredItems.isEmpty {
                        filteredEmptyState
                    } else {
                        VStack(spacing: 18) {
                            ForEach(categoryKeysInUse, id: \.self) { categoryKey in
                                if let categoryItems = grouped[categoryKey] {
                                    categorySection(
                                        title: categoryTitle(for: categoryKey),
                                        icon: categoryIcon(for: categoryKey),
                                        items: categoryItems
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Shopping")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search products")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !checkedIds.isEmpty {
                    Button("Clear bought") {
                        clearBought()
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Shopping list")
                    .font(.title2.weight(.bold))

                Text("This list is generated automatically from the current meal plan. Mark products as bought to track your progress.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var filteredItems: [ShoppingItem] {
        items.filter { item in
            matchesFilter(item) && matchesSearch(item)
        }
    }

    private var grouped: [String: [ShoppingItem]] {
        Dictionary(grouping: filteredItems, by: \.categoryKey)
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

    private var checkedIds: Set<String> {
        let parts = checkedIdsString
            .split(separator: ",")
            .map(String.init)

        return Set(parts.filter { !$0.isEmpty })
    }

    private var boughtItems: [ShoppingItem] {
        items.filter { checkedIds.contains($0.id) }
    }

    private var remainingItems: [ShoppingItem] {
        items.filter { !checkedIds.contains($0.id) }
    }

    @ViewBuilder
    private func categorySection(
        title: String,
        icon: String,
        items: [ShoppingItem]
    ) -> some View {
        AppCard {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)

                Spacer()

                Text("\(items.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(items) { item in
                    ShoppingItemRow(
                        item: item,
                        isChecked: checkedIds.contains(item.id)
                    ) {
                        toggleChecked(item.id)
                    }
                }
            }
        }
    }

    private var emptyPlanState: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("No shopping items yet")
                    .font(.headline)

                Text("Generate a meal plan first. Once the plan contains recipes, this screen will show the aggregated ingredients you need to buy.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var filteredEmptyState: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Nothing found")
                    .font(.headline)

                Text("Try another search phrase or switch the current filter.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func matchesFilter(_ item: ShoppingItem) -> Bool {
        switch filter {
        case .all:
            return true
        case .toBuy:
            return !checkedIds.contains(item.id)
        case .bought:
            return checkedIds.contains(item.id)
        }
    }

    private func matchesSearch(_ item: ShoppingItem) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else { return true }

        return item.name.localizedCaseInsensitiveContains(query)
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

    private func saveCheckedIds(_ set: Set<String>) {
        checkedIdsString = set.sorted().joined(separator: ",")
    }

    private func clearBought() {
        checkedIdsString = ""
    }

    private func categoryTitle(for key: String) -> String {
        switch key {
        case "category.meat":
            return "Protein"
        case "category.grain":
            return "Grains & legumes"
        case "category.vegetable":
            return "Vegetables"
        default:
            return "Other"
        }
    }

    private func categoryIcon(for key: String) -> String {
        switch key {
        case "category.meat":
            return "drumstick"
        case "category.grain":
            return "leaf"
        case "category.vegetable":
            return "carrot"
        default:
            return "basket"
        }
    }
}
