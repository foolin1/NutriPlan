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
                        "Фильтр",
                        subtitle: "Ищи продукты или переключайся между всеми, оставшимися и уже купленными."
                    )

                    AppCard {
                        Picker("Фильтр", selection: $filter) {
                            ForEach(ShoppingFilter.allCases) { value in
                                Text(value.rawValue).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    SectionTitleView(
                        "Список покупок",
                        subtitle: "Позиции сгруппированы по категориям и собраны из текущего плана питания."
                    )

                    if filteredItems.isEmpty {
                        filteredEmptyState
                    } else {
                        VStack(spacing: 18) {
                            ForEach(categoryKeysInUse, id: \.self) { categoryKey in
                                if let categoryItems = groupedItems[categoryKey] {
                                    categorySection(
                                        title: categoryTitle(for: categoryKey),
                                        icon: categoryIcon(for: categoryKey),
                                        categoryItems: categoryItems
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
        .navigationTitle("Покупки")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Поиск продуктов")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !checkedIds.isEmpty {
                    Button("Сбросить купленное") {
                        clearBought()
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Список покупок")
                    .font(.title2.weight(.bold))

                Text("Этот список формируется автоматически на основе текущего плана питания. Отмечай купленные продукты, чтобы отслеживать прогресс.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var filteredItems: [ShoppingItem] {
        items.filter { shoppingItem in
            matchesFilter(shoppingItem) && matchesSearch(shoppingItem)
        }
    }

    private var groupedItems: [String: [ShoppingItem]] {
        Dictionary(grouping: filteredItems, by: \.categoryKey)
    }

    private var categoryKeysInUse: [String] {
        let order = [
            "category.meat",
            "category.grain",
            "category.vegetable",
            "category.other"
        ]

        return order.filter { groupedItems[$0] != nil }
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
        categoryItems: [ShoppingItem]
    ) -> some View {
        AppCard {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)

                Spacer()

                Text("\(categoryItems.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(categoryItems) { shoppingItem in
                    ShoppingItemRow(
                        item: shoppingItem,
                        isChecked: checkedIds.contains(shoppingItem.id)
                    ) {
                        toggleChecked(shoppingItem.id)
                    }
                }
            }
        }
    }

    private var emptyPlanState: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Пока нет покупок")
                    .font(.headline)

                Text("Сначала сформируй план питания. Когда в плане появятся блюда, здесь автоматически отобразятся нужные ингредиенты.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var filteredEmptyState: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ничего не найдено")
                    .font(.headline)

                Text("Попробуй другой поисковый запрос или переключи фильтр.")
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
        var updated = checkedIds

        if updated.contains(id) {
            updated.remove(id)
        } else {
            updated.insert(id)
        }

        saveCheckedIds(updated)
    }

    private func saveCheckedIds(_ ids: Set<String>) {
        checkedIdsString = ids.sorted().joined(separator: ",")
    }

    private func clearBought() {
        checkedIdsString = ""
    }

    private func categoryTitle(for key: String) -> String {
        switch key {
        case "category.meat":
            return "Белки"
        case "category.grain":
            return "Крупы и бобовые"
        case "category.vegetable":
            return "Овощи"
        default:
            return "Другое"
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
