import SwiftUI

struct ShoppingListView: View {
    @ObservedObject var vm: PlanViewModel

    @State private var searchText: String = ""
    @State private var filter: ShoppingFilter = .all
    @State private var groupingMode: ShoppingGroupingMode = .category

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

                    controlsCard
                    quickActionsCard

                    SectionTitleView(
                        "Список покупок",
                        subtitle: listSubtitle
                    )

                    if filteredItems.isEmpty {
                        filteredEmptyState
                    } else {
                        VStack(spacing: 18) {
                            ForEach(sectionKeysInUse, id: \.self) { sectionKey in
                                if let sectionItems = groupedItems[sectionKey] {
                                    sectionCard(
                                        sectionKey: sectionKey,
                                        sectionItems: sectionItems
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
                if !remainingItems.isEmpty {
                    Button("Отметить всё") {
                        markAllRemainingAsBought()
                    }
                }

                if !checkedIds.isEmpty {
                    Button("Сбросить") {
                        vm.clearCheckedShoppingItems()
                    }
                }
            }
        }
    }

    private var items: [ShoppingItem] {
        vm.shoppingItems
    }

    private var checkedIds: Set<String> {
        vm.checkedShoppingItemIds
    }

    private var filteredItems: [ShoppingItem] {
        items.filter { item in
            matchesFilter(item) && matchesSearch(item)
        }
    }

    private var groupedItems: [String: [ShoppingItem]] {
        Dictionary(
            grouping: filteredItems,
            by: groupingKey(for:)
        )
        .mapValues { sectionItems in
            sectionItems.sorted {
                let lhsChecked = checkedIds.contains($0.id)
                let rhsChecked = checkedIds.contains($1.id)

                if lhsChecked != rhsChecked {
                    return !lhsChecked && rhsChecked
                }

                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }

    private var sectionKeysInUse: [String] {
        let preferredOrder: [String]

        switch groupingMode {
        case .category:
            preferredOrder = [
                "category.meat",
                "category.grain",
                "category.vegetable",
                "category.fruit",
                "category.dairy",
                "category.nuts",
                "category.other"
            ]

        case .status:
            preferredOrder = [
                "section.remaining",
                "section.bought"
            ]
        }

        let existing = Set(groupedItems.keys)
        let ordered = preferredOrder.filter { existing.contains($0) }
        let rest = groupedItems.keys
            .filter { !preferredOrder.contains($0) }
            .sorted()

        return ordered + rest
    }

    private var boughtItems: [ShoppingItem] {
        items.filter { checkedIds.contains($0.id) }
    }

    private var remainingItems: [ShoppingItem] {
        items.filter { !checkedIds.contains($0.id) }
    }

    private var totalWeight: Double {
        items.reduce(0) { $0 + $1.grams }
    }

    private var remainingWeight: Double {
        remainingItems.reduce(0) { $0 + $1.grams }
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Список покупок")
                    .font(.title2.weight(.bold))

                Text("Этот список формируется автоматически на основе текущего плана питания. Отмечай купленные продукты, чтобы понимать, что уже готово, а что ещё нужно взять.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var controlsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Фильтр")
                        .font(.headline)

                    Picker("Фильтр", selection: $filter) {
                        ForEach(ShoppingFilter.allCases) { value in
                            Text(value.rawValue).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Группировка")
                        .font(.headline)

                    Picker("Группировка", selection: $groupingMode) {
                        ForEach(ShoppingGroupingMode.allCases) { value in
                            Text(value.rawValue).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var quickActionsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Быстрые действия")
                    .font(.headline)

                HStack(spacing: 12) {
                    Button {
                        markAllRemainingAsBought()
                    } label: {
                        quickActionLabel(
                            title: "Отметить всё",
                            subtitle: "Закрыть оставшиеся покупки"
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(remainingItems.isEmpty)

                    Button {
                        vm.clearCheckedShoppingItems()
                    } label: {
                        quickActionLabel(
                            title: "Сбросить",
                            subtitle: "Вернуть все отметки"
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(checkedIds.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func quickActionLabel(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }

    @ViewBuilder
    private func sectionCard(
        sectionKey: String,
        sectionItems: [ShoppingItem]
    ) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Label(sectionTitle(for: sectionKey), systemImage: sectionIcon(for: sectionKey))
                        .font(.headline)

                    Spacer()

                    Text(sectionSummary(for: sectionItems))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    ForEach(sectionItems) { item in
                        ShoppingItemRow(
                            item: item,
                            isChecked: checkedIds.contains(item.id),
                            categoryTitle: categoryTitle(for: item.categoryKey)
                        ) {
                            vm.toggleShoppingItemChecked(item.id)
                        }
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

                Text("Попробуй другой поисковый запрос, переключи фильтр или вернись ко всем позициям списка.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var listSubtitle: String {
        switch groupingMode {
        case .category:
            return "Позиции сгруппированы по категориям продуктов, чтобы список было удобно использовать в магазине."
        case .status:
            return "Позиции сгруппированы по статусу, чтобы быстрее увидеть, что ещё осталось купить."
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

    private func groupingKey(for item: ShoppingItem) -> String {
        switch groupingMode {
        case .category:
            return item.categoryKey
        case .status:
            return checkedIds.contains(item.id) ? "section.bought" : "section.remaining"
        }
    }

    private func sectionTitle(for key: String) -> String {
        switch key {
        case "section.remaining":
            return "Осталось купить"
        case "section.bought":
            return "Уже куплено"
        default:
            return categoryTitle(for: key)
        }
    }

    private func sectionIcon(for key: String) -> String {
        switch key {
        case "section.remaining":
            return "cart"
        case "section.bought":
            return "checkmark.circle"
        default:
            return categoryIcon(for: key)
        }
    }

    private func sectionSummary(for sectionItems: [ShoppingItem]) -> String {
        let count = sectionItems.count
        let grams = sectionItems.reduce(0) { $0 + $1.grams }
        return "\(count) · \(formattedWeight(grams))"
    }

    private func categoryTitle(for key: String) -> String {
        switch key {
        case "category.meat":
            return "Белковые продукты"
        case "category.grain":
            return "Крупы и гарниры"
        case "category.vegetable":
            return "Овощи"
        case "category.fruit":
            return "Фрукты и ягоды"
        case "category.dairy":
            return "Молочные продукты"
        case "category.nuts":
            return "Орехи и семечки"
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
        case "category.fruit":
            return "apple.logo"
        case "category.dairy":
            return "drop"
        case "category.nuts":
            return "circle.hexagongrid"
        default:
            return "basket"
        }
    }

    private func formattedWeight(_ grams: Double) -> String {
        let measurement: Measurement<UnitMass> = grams >= 1000
            ? Measurement(value: grams / 1000.0, unit: .kilograms)
            : Measurement(value: grams, unit: .grams)

        return measurement.formatted(.measurement(width: .abbreviated))
    }

    private func markAllRemainingAsBought() {
        for item in remainingItems {
            vm.toggleShoppingItemChecked(item.id)
        }
    }
}
