import Foundation

extension PlanViewModel {
    func addManualFoodToDiary(
        foodId: String,
        grams: Double,
        mealType: MealType
    ) {
        guard foodsById[foodId] != nil else { return }

        let normalizedGrams = min(max((grams / 25.0).rounded() * 25.0, 25), 1500)
        let foodDisplayName = foodName(for: foodId)

        let manualRecipe = Recipe(
            id: "manual_food_\(UUID().uuidString)",
            name: foodDisplayName,
            ingredients: [
                RecipeIngredient(foodId: foodId, grams: normalizedGrams)
            ],
            cookTimeMinutes: nil,
            tags: Set([mealTag(for: mealType)]),
            isModified: false
        )

        let manualEntry = ConsumedFoodEntry(
            mealId: UUID(),
            mealType: mealType,
            title: "\(foodDisplayName) (\(Int(normalizedGrams)) г)",
            recipe: manualRecipe
        )

        var updatedEntries = diaryDay.entries
        updatedEntries.append(manualEntry)
        diaryDay = DiaryDay(entries: sortedManualDiaryEntries(updatedEntries))
    }

    private func sortedManualDiaryEntries(
        _ entries: [ConsumedFoodEntry]
    ) -> [ConsumedFoodEntry] {
        entries.sorted {
            let leftOrder = mealTypeOrderForManualDiary($0.mealType)
            let rightOrder = mealTypeOrderForManualDiary($1.mealType)

            if leftOrder != rightOrder {
                return leftOrder < rightOrder
            }

            return $0.loggedAt < $1.loggedAt
        }
    }

    private func mealTypeOrderForManualDiary(_ mealType: MealType) -> Int {
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

    private func mealTag(for mealType: MealType) -> String {
        switch mealType {
        case .breakfast:
            return "breakfast"
        case .lunch:
            return "lunch"
        case .dinner:
            return "dinner"
        case .snack:
            return "snack"
        }
    }
}
