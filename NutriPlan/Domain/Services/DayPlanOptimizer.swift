import Foundation

struct DayPlanScoreBreakdown: Hashable {
    let totalScore: Double

    let targetCalories: Double
    let targetProtein: Double
    let targetFat: Double
    let targetCarbs: Double

    let actualCalories: Double
    let actualProtein: Double
    let actualFat: Double
    let actualCarbs: Double

    let caloriePenalty: Double
    let proteinPenalty: Double
    let fatPenalty: Double
    let carbsPenalty: Double

    let mealQualityBonus: Double
    let coverageBonus: Double
    let nutrientBonus: Double

    let ironAmount: Double
    let focusedNutrientAmount: Double
    let mealCount: Int
}

enum DayPlanOptimizer {
    static func buildOptimizedDayPlan(
        goal: NutritionGoal?,
        candidatePools: [MealType: [Recipe]],
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus
    ) -> DayPlan {
        let orderedMealTypes = MealType.allCases.filter { !(candidatePools[$0] ?? []).isEmpty }
        guard !orderedMealTypes.isEmpty else { return .empty }

        var bestMeals: [PlannedMeal] = []
        var bestScore = -Double.infinity

        func search(
            index: Int,
            usedRecipeIds: Set<String>,
            selectedMeals: [PlannedMeal]
        ) {
            if index == orderedMealTypes.count {
                let breakdown = evaluate(
                    meals: selectedMeals,
                    goal: goal,
                    foodsById: foodsById,
                    nutrientFocus: nutrientFocus
                )

                if breakdown.totalScore > bestScore {
                    bestScore = breakdown.totalScore
                    bestMeals = selectedMeals
                }
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

        let sortedMeals = bestMeals.sorted { mealOrder($0.type) < mealOrder($1.type) }
        return DayPlan(meals: sortedMeals)
    }

    static func evaluate(
        meals: [PlannedMeal],
        goal: NutritionGoal?,
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus
    ) -> DayPlanScoreBreakdown {
        let totalSummary = summarize(
            meals: meals,
            foodsById: foodsById
        )

        let targetCalories = goal.map { Double($0.targetCalories) } ?? totalSummary.macros.calories
        let targetProtein = goal.map { Double($0.proteinGrams) } ?? totalSummary.macros.protein
        let targetFat = goal.map { Double($0.fatGrams) } ?? totalSummary.macros.fat
        let targetCarbs = goal.map { Double($0.carbsGrams) } ?? totalSummary.macros.carbs

        let actualCalories = totalSummary.macros.calories
        let actualProtein = totalSummary.macros.protein
        let actualFat = totalSummary.macros.fat
        let actualCarbs = totalSummary.macros.carbs

        let ironAmount = totalSummary.nutrients["iron", default: 0]
        let focusedNutrientAmount = NutrientCatalog.focusedAmount(
            in: totalSummary.nutrients,
            for: nutrientFocus
        )

        let caloriePenalty = relativePenalty(
            actual: actualCalories,
            target: targetCalories,
            fallback: 300
        ) * 45

        let proteinPenalty = relativePenalty(
            actual: actualProtein,
            target: targetProtein,
            fallback: 20
        ) * 25

        let fatPenalty = relativePenalty(
            actual: actualFat,
            target: targetFat,
            fallback: 15
        ) * 15

        let carbsPenalty = relativePenalty(
            actual: actualCarbs,
            target: targetCarbs,
            fallback: 30
        ) * 15

        let averageMealScore: Double
        if meals.isEmpty {
            averageMealScore = 0
        } else {
            let scores = meals.map {
                RecipeScorer.evaluate(
                    recipe: $0.recipe,
                    mealType: $0.type,
                    goal: goal,
                    foodsById: foodsById,
                    nutrientFocus: nutrientFocus
                ).totalScore
            }

            averageMealScore = scores.reduce(0, +) / Double(scores.count)
        }

        let mealQualityBonus = min(averageMealScore * 0.12, 12.0)
        let coverageBonus = min(Double(meals.count) * 2.0, 8.0)

        let nutrientBonus = NutrientCatalog.dayPlanBonus(
            for: nutrientFocus,
            amount: focusedNutrientAmount
        )

        let totalScore = min(
            max(
                100
                    - caloriePenalty
                    - proteinPenalty
                    - fatPenalty
                    - carbsPenalty
                    + mealQualityBonus
                    + coverageBonus
                    + nutrientBonus,
                0
            ),
            100
        )

        return DayPlanScoreBreakdown(
            totalScore: totalScore,
            targetCalories: targetCalories,
            targetProtein: targetProtein,
            targetFat: targetFat,
            targetCarbs: targetCarbs,
            actualCalories: actualCalories,
            actualProtein: actualProtein,
            actualFat: actualFat,
            actualCarbs: actualCarbs,
            caloriePenalty: caloriePenalty,
            proteinPenalty: proteinPenalty,
            fatPenalty: fatPenalty,
            carbsPenalty: carbsPenalty,
            mealQualityBonus: mealQualityBonus,
            coverageBonus: coverageBonus,
            nutrientBonus: nutrientBonus,
            ironAmount: ironAmount,
            focusedNutrientAmount: focusedNutrientAmount,
            mealCount: meals.count
        )
    }

    private static func summarize(
        meals: [PlannedMeal],
        foodsById: [String: Food]
    ) -> NutritionSummary {
        var totalMacros = Macros.zero
        var totalNutrients: [String: Double] = [:]

        for meal in meals {
            let mealSummary = NutritionCalculator.summarize(
                ingredients: meal.recipe.ingredients,
                foodsById: foodsById
            )

            totalMacros = totalMacros + mealSummary.macros

            for (key, value) in mealSummary.nutrients {
                totalNutrients[key, default: 0] += value
            }
        }

        return NutritionSummary(
            macros: totalMacros,
            nutrients: totalNutrients
        )
    }

    private static func relativePenalty(
        actual: Double,
        target: Double,
        fallback: Double
    ) -> Double {
        let denominator = max(target, fallback)
        return abs(actual - target) / denominator
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
