import Foundation

struct RankedDayPlanOption: Hashable {
    let meals: [PlannedMeal]
    let breakdown: DayPlanScoreBreakdown
}

private struct ShuffleCandidate {
    let option: RankedDayPlanOption
    let overlapCount: Int
    let scoreDistance: Double
}

enum DayPlanShuffleService {
    static func buildRankedOptions(
        goal: NutritionGoal?,
        candidatePools: [MealType: [Recipe]],
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus,
        maxOptions: Int = 12
    ) -> [RankedDayPlanOption] {
        let orderedMealTypes = MealType.allCases.filter { !(candidatePools[$0] ?? []).isEmpty }
        guard !orderedMealTypes.isEmpty else { return [] }

        var allOptions: [RankedDayPlanOption] = []

        func search(
            index: Int,
            usedRecipeIds: Set<String>,
            selectedMeals: [PlannedMeal]
        ) {
            if index == orderedMealTypes.count {
                let sortedMeals = selectedMeals.sorted { mealOrder($0.type) < mealOrder($1.type) }
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

        return uniqueOptions(allOptions)
            .sorted { left, right in
                if left.breakdown.totalScore != right.breakdown.totalScore {
                    return left.breakdown.totalScore > right.breakdown.totalScore
                }

                return signature(for: left.meals) < signature(for: right.meals)
            }
            .prefix(maxOptions)
            .map { $0 }
    }

    static func shuffledOption(
        from rankedOptions: [RankedDayPlanOption],
        currentMeals: [PlannedMeal]
    ) -> RankedDayPlanOption? {
        guard !rankedOptions.isEmpty else {
            return nil
        }

        let currentSignature = signature(for: currentMeals)
        let currentScore = rankedOptions.first(where: { signature(for: $0.meals) == currentSignature })?.breakdown.totalScore ?? 0

        let alternatives = rankedOptions.filter { signature(for: $0.meals) != currentSignature }

        guard !alternatives.isEmpty else {
            return rankedOptions.first
        }

        let rankedAlternatives = alternatives
            .map { option in
                ShuffleCandidate(
                    option: option,
                    overlapCount: overlapCount(
                        lhs: currentMeals,
                        rhs: option.meals
                    ),
                    scoreDistance: abs(option.breakdown.totalScore - currentScore)
                )
            }
            .sorted { left, right in
                if left.overlapCount != right.overlapCount {
                    return left.overlapCount < right.overlapCount
                }

                if left.scoreDistance != right.scoreDistance {
                    return left.scoreDistance < right.scoreDistance
                }

                if left.option.breakdown.totalScore != right.option.breakdown.totalScore {
                    return left.option.breakdown.totalScore > right.option.breakdown.totalScore
                }

                return signature(for: left.option.meals) < signature(for: right.option.meals)
            }

        let poolSize = min(4, rankedAlternatives.count)
        let pool = Array(rankedAlternatives.prefix(poolSize)).map(\.option)

        return pool.randomElement() ?? rankedAlternatives.first?.option
    }

    private static func uniqueOptions(_ options: [RankedDayPlanOption]) -> [RankedDayPlanOption] {
        var seen: Set<String> = []
        var result: [RankedDayPlanOption] = []

        for option in options {
            let key = signature(for: option.meals)

            if !seen.contains(key) {
                seen.insert(key)
                result.append(option)
            }
        }

        return result
    }

    private static func signature(for meals: [PlannedMeal]) -> String {
        meals
            .sorted { mealOrder($0.type) < mealOrder($1.type) }
            .map { "\($0.type.rawValue):\($0.recipe.id)" }
            .joined(separator: "|")
    }

    private static func overlapCount(lhs: [PlannedMeal], rhs: [PlannedMeal]) -> Int {
        let lhsIds = Set(lhs.map { $0.recipe.id })
        let rhsIds = Set(rhs.map { $0.recipe.id })
        return lhsIds.intersection(rhsIds).count
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
