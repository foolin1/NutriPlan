import Foundation

struct RankedDayPlanOption: Hashable {
    let meals: [PlannedMeal]
    let breakdown: DayPlanScoreBreakdown
}

enum DayPlanShuffleService {
    static func buildRankedOptions(
        goal: NutritionGoal?,
        candidatePools: [MealType: [Recipe]],
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus,
        maxOptions: Int = 12
    ) -> [RankedDayPlanOption] {
        let orderedMealTypes = MealType.allCases.filter {
            !(candidatePools[$0] ?? []).isEmpty
        }

        guard !orderedMealTypes.isEmpty else {
            return []
        }

        var allOptions: [RankedDayPlanOption] = []

        func search(
            index: Int,
            usedRecipeIds: Set<String>,
            selectedMeals: [PlannedMeal]
        ) {
            if index == orderedMealTypes.count {
                let sortedMeals = selectedMeals.sorted {
                    mealOrder($0.type) < mealOrder($1.type)
                }

                let breakdown = DayPlanOptimizer.evaluate(
                    meals: sortedMeals,
                    goal: goal,
                    foodsById: foodsById,
                    nutrientFocus: nutrientFocus
                )

                allOptions.append(
                    RankedDayPlanOption(
                        meals: sortedMeals,
                        breakdown: breakdown
                    )
                )
                return
            }

            let mealType = orderedMealTypes[index]
            let pool = candidatePools[mealType] ?? []

            var addedAtLeastOne = false

            for recipe in pool where !usedRecipeIds.contains(recipe.id) {
                addedAtLeastOne = true

                let plannedMeal = PlannedMeal(
                    type: mealType,
                    recipe: recipe
                )

                search(
                    index: index + 1,
                    usedRecipeIds: usedRecipeIds.union([recipe.id]),
                    selectedMeals: selectedMeals + [plannedMeal]
                )
            }

            if !addedAtLeastOne {
                search(
                    index: index + 1,
                    usedRecipeIds: usedRecipeIds,
                    selectedMeals: selectedMeals
                )
            }
        }

        search(
            index: 0,
            usedRecipeIds: [],
            selectedMeals: []
        )

        let unique = uniqueOptions(allOptions)

        return unique
            .sorted { $0.breakdown.totalScore > $1.breakdown.totalScore }
            .prefix(maxOptions)
            .map { $0 }
    }

    static func shuffledOption(
        from rankedOptions: [RankedDayPlanOption],
        currentMeals: [PlannedMeal]
    ) -> RankedDayPlanOption? {
        guard !rankedOptions.isEmpty else { return nil }

        let currentIds = Set(currentMeals.map { $0.recipe.id })

        let alternatives = rankedOptions.filter { option in
            Set(option.meals.map { $0.recipe.id }) != currentIds
        }

        if let alternative = alternatives.randomElement() {
            return alternative
        }

        return rankedOptions.dropFirst().randomElement() ?? rankedOptions.first
    }

    private static func uniqueOptions(
        _ options: [RankedDayPlanOption]
    ) -> [RankedDayPlanOption] {
        var seen: Set<String> = []
        var result: [RankedDayPlanOption] = []

        for option in options {
            let key = option.meals
                .sorted { mealOrder($0.type) < mealOrder($1.type) }
                .map { "\($0.type.rawValue):\($0.recipe.id)" }
                .joined(separator: "|")

            if !seen.contains(key) {
                seen.insert(key)
                result.append(option)
            }
        }

        return result
    }

    private static func mealOrder(_ mealType: MealType) -> Int {
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
}
