import Foundation

extension PlanViewModel {
    func decreaseIngredientPortion(
        mealId: UUID,
        ingredientIndex: Int,
        step: Double = 25,
        minGrams: Double = 25,
        maxGrams: Double = 500
    ) {
        changeIngredientGrams(
            mealId: mealId,
            ingredientIndex: ingredientIndex,
            delta: -step,
            step: step,
            minGrams: minGrams,
            maxGrams: maxGrams
        )
    }

    func increaseIngredientPortion(
        mealId: UUID,
        ingredientIndex: Int,
        step: Double = 25,
        minGrams: Double = 25,
        maxGrams: Double = 500
    ) {
        changeIngredientGrams(
            mealId: mealId,
            ingredientIndex: ingredientIndex,
            delta: step,
            step: step,
            minGrams: minGrams,
            maxGrams: maxGrams
        )
    }

    func changeIngredientGrams(
        mealId: UUID,
        ingredientIndex: Int,
        delta: Double,
        step: Double = 25,
        minGrams: Double = 25,
        maxGrams: Double = 500
    ) {
        guard let mealIndex = dayPlan.meals.firstIndex(where: { $0.id == mealId }) else {
            return
        }

        guard dayPlan.meals[mealIndex].recipe.ingredients.indices.contains(ingredientIndex) else {
            return
        }

        var updatedMeals = dayPlan.meals
        let currentIngredient = updatedMeals[mealIndex].recipe.ingredients[ingredientIndex]

        let candidateValue = currentIngredient.grams + delta
        let snappedValue = snapToStep(candidateValue, step: step)
        let finalValue = min(max(snappedValue, minGrams), maxGrams)

        guard abs(finalValue - currentIngredient.grams) >= 0.1 else {
            return
        }

        updatedMeals[mealIndex].recipe.ingredients[ingredientIndex].grams = finalValue
        updatedMeals[mealIndex].recipe.isModified = true

        dayPlan = DayPlan(meals: updatedMeals)
        syncDiaryEntryIfNeeded(mealId: mealId)
    }

    private func syncDiaryEntryIfNeeded(mealId: UUID) {
        guard let diaryIndex = diaryDay.entries.firstIndex(where: { $0.mealId == mealId }),
              let updatedMeal = meal(with: mealId) else {
            return
        }

        var updatedEntries = diaryDay.entries
        updatedEntries[diaryIndex].recipe = updatedMeal.recipe
        updatedEntries[diaryIndex].title = displayTitle(for: updatedMeal.recipe)

        diaryDay = DiaryDay(entries: sortedDiaryEntriesForPortionUpdate(updatedEntries))
    }

    private func sortedDiaryEntriesForPortionUpdate(
        _ entries: [ConsumedFoodEntry]
    ) -> [ConsumedFoodEntry] {
        entries.sorted {
            if mealTypeOrderForPortionUpdate($0.mealType) != mealTypeOrderForPortionUpdate($1.mealType) {
                return mealTypeOrderForPortionUpdate($0.mealType) < mealTypeOrderForPortionUpdate($1.mealType)
            }

            return $0.loggedAt < $1.loggedAt
        }
    }

    private func mealTypeOrderForPortionUpdate(_ mealType: MealType) -> Int {
        switch mealType {
        case .breakfast:
            return 0
        case .lunch:
            return 1
        case .dinner:
            return 2
        case .snack:
            return 3
        }
    }

    private func snapToStep(_ value: Double, step: Double) -> Double {
        guard step > 0 else { return value }
        return (value / step).rounded() * step
    }
}
