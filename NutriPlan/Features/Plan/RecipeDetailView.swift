import SwiftUI

struct RecipeDetailView: View {
    let mealId: UUID
    @ObservedObject var vm: PlanViewModel

    @State private var pickedIndex: Int? = nil

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

        List {
            Section("Сводка") {
                Text("Калории: \(Int(summary.macros.calories))")
                Text(
                    "Б: \(summary.macros.protein, specifier: "%.1f") Ж: \(summary.macros.fat, specifier: "%.1f") У: \(summary.macros.carbs, specifier: "%.1f")"
                )
            }

            Section("Микронутриенты") {
                ForEach(NutrientCatalog.focusable) { nutrient in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(nutrient.name)

                            if let target = nutrient.targetPerDay {
                                Text("Ориентир: \(amountText(target, unit: nutrient.unit))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Text(amountText(summary.nutrients[nutrient.id, default: 0], unit: nutrient.unit))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Почему блюдо попало в план") {
                InfoValueRow(title: "Итоговая оценка", value: String(format: "%.1f", scoreBreakdown.totalScore))
                InfoValueRow(title: "Калории блюда", value: "\(Int(scoreBreakdown.actualCalories)) ккал")
                InfoValueRow(title: "Белки", value: String(format: "%.1f г", scoreBreakdown.actualProtein))
                InfoValueRow(title: "Жиры", value: String(format: "%.1f г", scoreBreakdown.actualFat))
                InfoValueRow(title: "Углеводы", value: String(format: "%.1f г", scoreBreakdown.actualCarbs))

                if let focusedNutrient = vmFocusedNutrient(from: recipe) {
                    Divider()
                    InfoValueRow(title: "Фокус", value: focusedNutrient.title)
                    InfoValueRow(title: "Значение", value: focusedNutrient.amount)
                }
            }

            Section("Ингредиенты") {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    ingredientRow(
                        mealId: meal.id,
                        ingredientIndex: index,
                        ingredient: ingredient
                    )
                }
            }

            Section("Действия") {
                Button {
                    vm.addMealToDiary(mealId: mealId)
                } label: {
                    Text(vm.isMealLogged(mealId) ? "Обновить запись в дневнике" : "Добавить в дневник")
                }

                if vm.isMealLogged(mealId) {
                    Text("Это блюдо уже добавлено в дневник.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(vm.displayTitle(for: recipe))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func ingredientRow(
        mealId: UUID,
        ingredientIndex: Int,
        ingredient: RecipeIngredient
    ) -> some View {
        let foodName = vm.foodName(for: ingredient.foodId)
        let candidates = vm.substitutionCandidates(for: ingredient)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(foodName)
                Spacer()
                Text("\(Int(ingredient.grams.rounded())) г")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    adjustIngredientPortion(
                        mealId: mealId,
                        ingredientIndex: ingredientIndex,
                        delta: -portionStep
                    )
                } label: {
                    Image(systemName: "minus.circle")
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
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .foregroundStyle(.accentColor)

            if !candidates.isEmpty {
                Menu("Замена") {
                    ForEach(candidates, id: \.food.id) { candidate in
                        Button {
                            vm.applySubstitution(
                                mealId: mealId,
                                ingredientIndex: ingredientIndex,
                                newFoodId: candidate.food.id
                            )
                        } label: {
                            Text("\(vm.foodName(for: candidate.food.id)) — \(Int(candidate.score.rounded()))")
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
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

        guard let sameFoodCandidate = vm.substitutionCandidates(
            for: meal.recipe.ingredients[ingredientIndex]
        ).first(where: { $0.food.id == meal.recipe.ingredients[ingredientIndex].foodId }) else {
            var updatedMeal = meal
            updatedMeal.recipe.ingredients[ingredientIndex].grams = newValue
            return
        }

        _ = sameFoodCandidate

        var updatedMeals = vm.dayPlan.meals
        guard let mealIndex = updatedMeals.firstIndex(where: { $0.id == mealId }) else { return }
        updatedMeals[mealIndex].recipe.ingredients[ingredientIndex].grams = newValue
        updatedMeals[mealIndex].recipe.isModified = true
        vm.dayPlan = DayPlan(meals: updatedMeals)
    }

    private func vmFocusedNutrient(from recipe: Recipe) -> (title: String, amount: String)? {
        let summary = vm.summary(for: recipe)
        let focus = vm.recipeSelectionBreakdown(
            for: recipe,
            mealType: .snack
        )

        _ = focus

        guard let currentMeal = vm.meal(with: mealId) else { return nil }
        let currentBreakdown = vm.recipeSelectionBreakdown(
            for: recipe,
            mealType: currentMeal.type
        )

        let nutrientAmount = currentBreakdown.focusedNutrientAmount
        guard nutrientAmount > 0 else { return nil }

        guard let appNutrientFocus = currentFocusedNutrientFocus(),
              let nutrient = NutrientCatalog.nutrient(for: appNutrientFocus) else {
            return nil
        }

        return (
            title: nutrient.name,
            amount: amountText(nutrientAmount, unit: nutrient.unit)
        )
    }

    private func currentFocusedNutrientFocus() -> NutrientFocus? {
        for focus in NutrientFocus.allCases where focus != .none {
            if let nutrient = NutrientCatalog.nutrient(for: focus),
               vm.daySummary().nutrients.keys.contains(nutrient.id) {
                return focus
            }
        }
        return nil
    }

    private func amountText(_ value: Double, unit: String) -> String {
        String(format: "%.1f %@", value, unit)
    }
}
