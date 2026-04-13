import SwiftUI

struct ManualDiaryEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: PlanViewModel

    @State private var searchText: String = ""
    @State private var selectedMealType: MealType = .snack
    @State private var gramsText: String = "100"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    settingsCard

                    SectionTitleView(
                        "Каталог продуктов",
                        subtitle: "Выбери продукт, который был съеден фактически. Он будет добавлен в дневник как отдельная запись."
                    )

                    if filteredFoods.isEmpty {
                        emptySearchState
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredFoods, id: \.id) { food in
                                foodCard(for: food)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Добавить вручную")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Поиск продукта")
        }
    }

    private var filteredFoods: [Food] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return Array(vm.allFoods.prefix(30))
        }

        return vm.allFoods.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    private var validGrams: Double? {
        let normalized = gramsText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let value = Double(normalized), value > 0 else {
            return nil
        }

        return min(value, 1500)
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ручное добавление")
                    .font(.title2.weight(.bold))

                Text("Используй этот режим, если пользователь ел не по предложенному плану. Достаточно выбрать продукт, указать граммовку и приём пищи.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var settingsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Параметры записи")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Приём пищи")
                        .font(.subheadline.weight(.semibold))

                    Picker("Приём пищи", selection: $selectedMealType) {
                        ForEach(MealType.allCases) { mealType in
                            Text(mealType.ruTitle).tag(mealType)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Граммовка")
                        .font(.subheadline.weight(.semibold))

                    TextField("Например, 120", text: $gramsText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)

                    if validGrams == nil {
                        Text("Введите корректное количество граммов.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text("Запись будет добавлена с указанной граммовкой.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func foodCard(for food: Food) -> some View {
        let previewMacros = scaledMacros(for: food)

        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(food.name)
                    .font(.headline)

                VStack(spacing: 8) {
                    InfoValueRow(title: "Калории", value: "\(Int(previewMacros.calories)) ккал")
                    InfoValueRow(title: "Белки", value: String(format: "%.1f г", previewMacros.protein))
                    InfoValueRow(title: "Жиры", value: String(format: "%.1f г", previewMacros.fat))
                    InfoValueRow(title: "Углеводы", value: String(format: "%.1f г", previewMacros.carbs))
                }

                Button {
                    guard let grams = validGrams else { return }
                    vm.addManualFoodEntry(
                        foodId: food.id,
                        grams: grams,
                        mealType: selectedMealType
                    )
                    dismiss()
                } label: {
                    Text(buttonTitle(for: food))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(validGrams == nil ? Color.gray.opacity(0.18) : Color.accentColor.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .disabled(validGrams == nil)
            }
        }
    }

    private var emptySearchState: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ничего не найдено")
                    .font(.headline)

                Text("Попробуй изменить поисковый запрос или очистить строку поиска.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func scaledMacros(for food: Food) -> Macros {
        let grams = validGrams ?? 100
        let factor = grams / 100.0

        return Macros(
            calories: food.macrosPer100g.calories * factor,
            protein: food.macrosPer100g.protein * factor,
            fat: food.macrosPer100g.fat * factor,
            carbs: food.macrosPer100g.carbs * factor
        )
    }

    private func buttonTitle(for food: Food) -> String {
        guard let grams = validGrams else {
            return "Введите граммовку"
        }

        let displayGrams: String
        if abs(grams.rounded() - grams) < 0.001 {
            displayGrams = "\(Int(grams.rounded()))"
        } else {
            displayGrams = String(format: "%.0f", grams)
        }

        return "Добавить \(food.name) — \(displayGrams) г"
    }
}
