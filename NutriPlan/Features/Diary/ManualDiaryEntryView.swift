import SwiftUI

struct ManualDiaryEntryView: View {
    @ObservedObject var vm: PlanViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMealType: MealType = .snack
    @State private var selectedFoodId: String? = nil
    @State private var grams: Double = 150
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    mealTypeCard
                    gramsCard

                    if let selectedFood = selectedFood {
                        selectedFoodCard(selectedFood)
                    }

                    SectionTitleView(
                        "Поиск продукта",
                        subtitle: "Начни вводить название продукта, чтобы быстро найти его в каталоге."
                    )

                    if trimmedSearchText.isEmpty {
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Начни вводить название")
                                    .font(.headline)

                                Text("Список продуктов появится после ввода текста в строке поиска. Так будет удобнее, чем просматривать весь каталог вручную.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else if filteredFoods.isEmpty {
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Ничего не найдено")
                                    .font(.headline)

                                Text("Попробуй изменить запрос или ввести только часть названия.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFoods) { food in
                                foodRow(food)
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 120)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Добавить запись")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Поиск продукта")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedFood: Food? {
        guard let selectedFoodId else { return nil }
        return vm.foodsById[selectedFoodId]
    }

    private var filteredFoods: [Food] {
        guard !trimmedSearchText.isEmpty else { return [] }

        return vm.foodsById.values
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .filter { food in
                food.name.localizedCaseInsensitiveContains(trimmedSearchText)
            }
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ручное добавление в дневник")
                    .font(.title2.weight(.bold))

                Text("Если ты ел не по плану, можно вручную добавить продукт из каталога и указать его количество.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var mealTypeCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Приём пищи")
                    .font(.headline)

                Picker("Приём пищи", selection: $selectedMealType) {
                    ForEach(MealType.allCases) { value in
                        Text(value.ruTitle).tag(value)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var gramsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Количество")
                    .font(.headline)

                HStack {
                    Text("Вес")
                    Spacer()
                    Text("\(Int(grams)) г")
                        .foregroundStyle(.secondary)
                }

                Stepper(value: $grams, in: 25...1500, step: 25) {
                    Text("Изменить количество")
                }
            }
        }
    }

    @ViewBuilder
    private func selectedFoodCard(_ food: Food) -> some View {
        let factor = grams / 100.0
        let macros = food.macrosPer100g * factor
        let iron = food.nutrientsPer100g["iron", default: 0] * factor

        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Выбранный продукт")
                    .font(.headline)

                Text(food.name)
                    .font(.title3.weight(.semibold))

                RecipeSummaryGrid(
                    caloriesText: "\(Int(macros.calories)) ккал",
                    proteinText: String(format: "%.1f г", macros.protein),
                    fatText: String(format: "%.1f г", macros.fat),
                    carbsText: String(format: "%.1f г", macros.carbs),
                    ironText: iron > 0 ? String(format: "%.2f мг", iron) : nil
                )
            }
        }
    }

    @ViewBuilder
    private func foodRow(_ food: Food) -> some View {
        let isSelected = selectedFoodId == food.id

        Button {
            selectedFoodId = food.id
        } label: {
            AppCard {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(food.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("\(Int(food.macrosPer100g.calories)) ккал на 100 г")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: 12) {
                if let selectedFood {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedFood.name)
                                .font(.subheadline.weight(.semibold))
                            Text("\(Int(grams)) г • \(selectedMealType.ruTitle.lowercased())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }

                Button {
                    saveManualEntry()
                } label: {
                    Text("Добавить в дневник")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(selectedFood == nil ? Color(.tertiarySystemFill) : Color.accentColor.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .disabled(selectedFood == nil)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
    }

    private func saveManualEntry() {
        guard let selectedFoodId else { return }

        vm.addManualFoodToDiary(
            foodId: selectedFoodId,
            grams: grams,
            mealType: selectedMealType
        )
        dismiss()
    }
}
