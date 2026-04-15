import SwiftUI

struct RecipeDetailView: View {
    let mealId: UUID

    @ObservedObject var vm: PlanViewModel
    @EnvironmentObject private var appState: AppState

    @State private var pickedIngredientIndex: Int? = nil

    private let portionStep: Double = 25
    private let minIngredientGrams: Double = 25
    private let maxIngredientGrams: Double = 500

    var body: some View {
        Group {
            if let meal = vm.meal(with: mealId) {
                content(for: meal)
            } else {
                unavailableState
            }
        }
    }

    @ViewBuilder
    private func content(for meal: PlannedMeal) -> some View {
        let recipe = meal.recipe
        let summary = vm.summary(for: recipe)
        let scoreBreakdown = vm.recipeSelectionBreakdown(
            for: recipe,
            mealType: meal.type
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitleView(
                    "Почему блюдо попало в план",
                    subtitle: "Краткое объяснение, насколько блюдо подходит под текущую цель и выбранный фокус."
                )

                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoValueRow(title: "Итоговая оценка", value: String(format: "%.1f", scoreBreakdown.totalScore))
                        Divider()
                        InfoValueRow(title: "Калории блюда", value: "\(Int(scoreBreakdown.actualCalories.rounded())) ккал")
                        InfoValueRow(title: "Белки", value: String(format: "%.1f г", scoreBreakdown.actualProtein))
                        InfoValueRow(title: "Жиры", value: String(format: "%.1f г", scoreBreakdown.actualFat))
                        InfoValueRow(title: "Углеводы", value: String(format: "%.1f г", scoreBreakdown.actualCarbs))

                        if let focusedNutrient = focusedNutrientInfo(from: scoreBreakdown) {
                            Divider()
                            InfoValueRow(title: "Фокус", value: focusedNutrient.title)
                            InfoValueRow(title: "Значение", value: focusedNutrient.amount)
                        }
                    }
                }

                SectionTitleView(
                    "Микронутриенты",
                    subtitle: "Содержание ключевых витаминов и минералов в выбранном блюде."
                )

                AppCard {
                    VStack(spacing: 0) {
                        ForEach(Array(NutrientCatalog.focusable.enumerated()), id: \.offset) { index, nutrient in
                            HStack {
                                Text(nutrient.name)

                                Spacer()

                                Text(amountText(summary.nutrients[nutrient.id, default: 0], unit: nutrient.unit))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 12)

                            if index < NutrientCatalog.focusable.count - 1 {
                                Divider()
                            }
                        }
                    }
                }

                SectionTitleView(
                    "Ингредиенты",
                    subtitle: "Можно менять количество ингредиентов и подбирать подходящие замены."
                )

                AppCard {
                    VStack(spacing: 0) {
                        ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                            ingredientRow(
                                mealId: meal.id,
                                ingredientIndex: index,
                                ingredient: ingredient
                            )

                            if index < recipe.ingredients.count - 1 {
                                Divider()
                            }
                        }
                    }
                }

                SectionTitleView(
                    "Действия",
                    subtitle: "Добавь блюдо в дневник или обнови существующую запись."
                )

                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            vm.addMealToDiary(mealId: mealId)
                        } label: {
                            HStack {
                                Image(systemName: vm.isMealLogged(mealId) ? "arrow.trianglehead.clockwise" : "plus.circle.fill")
                                Text(vm.isMealLogged(mealId) ? "Обновить запись в дневнике" : "Добавить в дневник")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.12))
                            )
                        }
                        .buttonStyle(.plain)

                        if vm.isMealLogged(mealId) {
                            Text("Это блюдо уже добавлено в дневник.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(vm.displayTitle(for: recipe))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $pickedIngredientIndex.asIdentifiable) { wrapped in
            substitutionSheet(for: wrapped.value)
        }
    }

    @ViewBuilder
    private func ingredientRow(
        mealId: UUID,
        ingredientIndex: Int,
        ingredient: RecipeIngredient
    ) -> some View {
        let foodName = localizedFoodName(for: ingredient.foodId)
        let candidates = vm.substitutionCandidates(for: ingredient)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(foodName)
                        .font(.body)

                    Text("Количество: \(Int(ingredient.grams.rounded())) г")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(Int(ingredient.grams.rounded())) г")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                Button {
                    adjustIngredientPortion(
                        mealId: mealId,
                        ingredientIndex: ingredientIndex,
                        delta: -portionStep
                    )
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Button {
                    adjustIngredientPortion(
                        mealId: mealId,
                        ingredientIndex: ingredientIndex,
                        delta: portionStep
                    )
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .foregroundStyle(Color.accentColor)

            if !candidates.isEmpty {
                Button {
                    pickedIngredientIndex = ingredientIndex
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Показать замены")
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func substitutionSheet(for ingredientIndex: Int) -> some View {
        if let currentMeal = vm.meal(with: mealId),
           currentMeal.recipe.ingredients.indices.contains(ingredientIndex) {
            let ingredient = currentMeal.recipe.ingredients[ingredientIndex]
            let originalName = localizedFoodName(for: ingredient.foodId)
            let candidates = vm.substitutionCandidates(for: ingredient)

            NavigationStack {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Исходный ингредиент")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(originalName)
                                .font(.headline)

                            Text("Количество: \(Int(ingredient.grams.rounded())) г")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Варианты замены") {
                        ForEach(candidates) { candidate in
                            Button {
                                vm.applySubstitution(
                                    mealId: mealId,
                                    ingredientIndex: ingredientIndex,
                                    newFoodId: candidate.id
                                )
                                pickedIngredientIndex = nil
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .top, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(localizedFoodName(for: candidate.id, fallback: candidate.name))
                                                .foregroundStyle(.primary)
                                        }

                                        Spacer()

                                        Text("Оценка замены: \(scoreText(candidate.score))")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        deltaRow(title: "Калории", value: candidate.deltaMacros.calories, unit: "ккал")
                                        deltaRow(title: "Белки", value: candidate.deltaMacros.protein, unit: "г")
                                        deltaRow(title: "Жиры", value: candidate.deltaMacros.fat, unit: "г")
                                        deltaRow(title: "Углеводы", value: candidate.deltaMacros.carbs, unit: "г")
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .navigationTitle("Замена ингредиента")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Готово") {
                            pickedIngredientIndex = nil
                        }
                    }
                }
            }
        } else {
            NavigationStack {
                Text("Ингредиент не найден")
                    .padding()
                    .navigationTitle("Замена ингредиента")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    @ViewBuilder
    private func deltaRow(title: String, value: Double, unit: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(deltaText(value, unit: unit))
                .font(.caption.weight(.medium))
                .foregroundStyle(valueColor(value))
        }
    }

    private var unavailableState: some View {
        ContentUnavailableView(
            "Блюдо недоступно",
            systemImage: "fork.knife.circle",
            description: Text("Не удалось найти выбранное блюдо в текущем плане.")
        )
    }

    private func adjustIngredientPortion(
        mealId: UUID,
        ingredientIndex: Int,
        delta: Double
    ) {
        guard let meal = vm.meal(with: mealId) else { return }
        guard meal.recipe.ingredients.indices.contains(ingredientIndex) else { return }

        let current = meal.recipe.ingredients[ingredientIndex].grams
        let newValue = min(max(current + delta, minIngredientGrams), maxIngredientGrams)

        var updatedMeals = vm.dayPlan.meals
        guard let mealIndex = updatedMeals.firstIndex(where: { $0.id == mealId }) else { return }

        updatedMeals[mealIndex].recipe.ingredients[ingredientIndex].grams = newValue
        updatedMeals[mealIndex].recipe.isModified = true
        vm.dayPlan = DayPlan(meals: updatedMeals)
    }

    private func focusedNutrientInfo(
        from scoreBreakdown: RecipeScoreBreakdown
    ) -> (title: String, amount: String)? {
        let focus = appState.userProfile?.nutrientFocus ?? .none
        guard focus != .none else { return nil }
        guard let nutrient = NutrientCatalog.nutrient(for: focus) else { return nil }
        guard scoreBreakdown.focusedNutrientAmount > 0 else { return nil }

        return (
            title: nutrient.name,
            amount: amountText(scoreBreakdown.focusedNutrientAmount, unit: nutrient.unit)
        )
    }

    private func scoreText(_ score: Double) -> String {
        let normalized = max(0, min(score / 10.0, 10.0))
        return String(format: "%.1f/10", normalized)
    }

    private func localizedFoodName(for foodId: String, fallback: String? = nil) -> String {
        switch foodId {
        case "chicken_breast":
            return "Куриная грудка"
        case "turkey_breast":
            return "Грудка индейки"
        case "lean_beef":
            return "Постная говядина"
        case "veal":
            return "Телятина"
        case "salmon":
            return "Лосось"
        case "tuna":
            return "Тунец"
        case "cod":
            return "Треска"
        case "shrimp":
            return "Креветки"
        case "eggs":
            return "Яйца"
        case "tofu":
            return "Тофу"
        case "rice":
            return "Рис"
        case "quinoa":
            return "Киноа"
        case "buckwheat":
            return "Гречка"
        case "bulgur":
            return "Булгур"
        case "wholegrain_pasta":
            return "Цельнозерновая паста"
        case "potato":
            return "Картофель"
        case "sweet_potato":
            return "Батат"
        case "oats":
            return "Овсяные хлопья"
        case "wholegrain_bread":
            return "Цельнозерновой хлеб"
        case "lentils":
            return "Чечевица"
        case "chickpeas":
            return "Нут"
        case "red_beans":
            return "Красная фасоль"
        case "greek_yogurt":
            return "Греческий йогурт"
        case "cottage_cheese":
            return "Творог"
        case "milk":
            return "Молоко"
        case "kefir":
            return "Кефир"
        case "hard_cheese":
            return "Твёрдый сыр"
        case "blueberries":
            return "Черника"
        case "strawberries":
            return "Клубника"
        case "raspberries":
            return "Малина"
        case "banana":
            return "Банан"
        case "apple":
            return "Яблоко"
        case "pear":
            return "Груша"
        case "orange":
            return "Апельсин"
        case "kiwi":
            return "Киви"
        case "grapefruit":
            return "Грейпфрут"
        case "avocado":
            return "Авокадо"
        case "spinach":
            return "Шпинат"
        case "broccoli":
            return "Брокколи"
        case "bell_pepper_red":
            return "Красный сладкий перец"
        case "cucumber":
            return "Огурец"
        case "tomato":
            return "Помидор"
        case "zucchini":
            return "Кабачок"
        case "beetroot":
            return "Свёкла"
        case "carrot":
            return "Морковь"
        case "mushrooms":
            return "Шампиньоны"
        case "pumpkin_seeds":
            return "Тыквенные семечки"
        case "almonds":
            return "Миндаль"
        case "walnuts":
            return "Грецкий орех"
        case "dark_chocolate":
            return "Тёмный шоколад"
        default:
            return fallback ?? vm.foodName(for: foodId)
        }
    }

    private func amountText(_ value: Double, unit: String) -> String {
        String(format: "%.1f %@", value, unit)
    }

    private func deltaText(_ value: Double, unit: String) -> String {
        if unit == "ккал" {
            return String(format: "%+.0f %@", value, unit)
        }

        return String(format: "%+.1f %@", value, unit)
    }

    private func valueColor(_ value: Double) -> Color {
        if abs(value) < 0.05 {
            return .secondary
        }

        return value > 0 ? .green : .red
    }
}

private struct IdentifiedInt: Identifiable {
    let id = UUID()
    let value: Int
}

private extension Binding where Value == Int? {
    var asIdentifiable: Binding<IdentifiedInt?> {
        Binding<IdentifiedInt?>(
            get: { wrappedValue.map { IdentifiedInt(value: $0) } },
            set: { wrappedValue = $0?.value }
        )
    }
}
