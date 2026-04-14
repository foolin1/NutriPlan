import Foundation

private struct PortionAdjustmentCandidate {
    let mealIndex: Int
    let ingredientIndex: Int
    let step: Double
    let gain: Double
}

private struct AdjustmentProfile {
    let step: Double
    let maxGrams: Double
}

private enum DeficitLevel {
    case low
    case medium
    case high
}

enum DayPlanPortionOptimizer {
    static func optimize(
        dayPlan: DayPlan,
        goal: NutritionGoal?,
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus
    ) -> DayPlan {
        guard let goal, !dayPlan.meals.isEmpty else {
            return dayPlan
        }

        var meals = dayPlan.meals
        let maxIterations = 40

        for _ in 0..<maxIterations {
            let currentSummary = summarize(meals: meals, foodsById: foodsById)

            if isCloseEnough(summary: currentSummary, goal: goal) {
                break
            }

            guard let candidate = bestCandidate(
                meals: meals,
                goal: goal,
                foodsById: foodsById,
                nutrientFocus: nutrientFocus
            ) else {
                break
            }

            guard candidate.gain > 0.01 else {
                break
            }

            meals[candidate.mealIndex]
                .recipe
                .ingredients[candidate.ingredientIndex]
                .grams += candidate.step
        }

        let sortedMeals = meals.sorted {
            mealOrder($0.type) < mealOrder($1.type)
        }

        return DayPlan(meals: sortedMeals)
    }

    private static func bestCandidate(
        meals: [PlannedMeal],
        goal: NutritionGoal,
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus
    ) -> PortionAdjustmentCandidate? {
        let currentSummary = summarize(meals: meals, foodsById: foodsById)
        let currentFitness = fitness(
            summary: currentSummary,
            goal: goal,
            nutrientFocus: nutrientFocus
        )
        let calorieDeficit = Double(goal.targetCalories) - currentSummary.macros.calories
        let deficitLevel = level(for: calorieDeficit)

        var best: PortionAdjustmentCandidate?

        for mealIndex in meals.indices {
            for ingredientIndex in meals[mealIndex].recipe.ingredients.indices {
                let ingredient = meals[mealIndex].recipe.ingredients[ingredientIndex]

                guard let food = foodsById[ingredient.foodId] else {
                    continue
                }

                let profile = adjustmentProfile(
                    for: food,
                    level: deficitLevel
                )

                let newGrams = ingredient.grams + profile.step
                guard newGrams <= profile.maxGrams else {
                    continue
                }

                var updatedMeals = meals
                updatedMeals[mealIndex].recipe.ingredients[ingredientIndex].grams = newGrams

                let newSummary = summarize(meals: updatedMeals, foodsById: foodsById)
                let newFitness = fitness(
                    summary: newSummary,
                    goal: goal,
                    nutrientFocus: nutrientFocus
                )

                let gain = newFitness - currentFitness

                if best == nil || gain > (best?.gain ?? -Double.infinity) {
                    best = PortionAdjustmentCandidate(
                        mealIndex: mealIndex,
                        ingredientIndex: ingredientIndex,
                        step: profile.step,
                        gain: gain
                    )
                }
            }
        }

        return best
    }

    private static func fitness(
        summary: NutritionSummary,
        goal: NutritionGoal,
        nutrientFocus: NutrientFocus
    ) -> Double {
        let calorieGap = abs(Double(goal.targetCalories) - summary.macros.calories)
        let proteinGap = abs(Double(goal.proteinGrams) - summary.macros.protein)
        let fatGap = abs(Double(goal.fatGrams) - summary.macros.fat)
        let carbsGap = abs(Double(goal.carbsGrams) - summary.macros.carbs)

        let caloriePenalty = calorieGap * 0.95
        let proteinPenalty = proteinGap * 16.0
        let fatPenalty = fatGap * 12.0
        let carbsPenalty = carbsGap * 8.0

        let focusedNutrientAmount = NutrientCatalog.focusedAmount(
            in: summary.nutrients,
            for: nutrientFocus
        )

        let nutrientBonus: Double
        switch nutrientFocus {
        case .none:
            nutrientBonus = 0
        case .iron:
            nutrientBonus = min(focusedNutrientAmount * 1.5, 12.0)
        case .calcium:
            nutrientBonus = min(focusedNutrientAmount * 0.012, 12.0)
        case .magnesium:
            nutrientBonus = min(focusedNutrientAmount * 0.02, 12.0)
        case .vitaminC:
            nutrientBonus = min(focusedNutrientAmount * 0.05, 12.0)
        }

        return 10_000.0
            - caloriePenalty
            - proteinPenalty
            - fatPenalty
            - carbsPenalty
            + nutrientBonus
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

    private static func isCloseEnough(
        summary: NutritionSummary,
        goal: NutritionGoal
    ) -> Bool {
        let calorieGap = abs(Double(goal.targetCalories) - summary.macros.calories)
        let proteinGap = abs(Double(goal.proteinGrams) - summary.macros.protein)
        let fatGap = abs(Double(goal.fatGrams) - summary.macros.fat)
        let carbsGap = abs(Double(goal.carbsGrams) - summary.macros.carbs)

        return calorieGap <= 100
            && proteinGap <= 10
            && fatGap <= 8
            && carbsGap <= 12
    }

    private static func level(for calorieDeficit: Double) -> DeficitLevel {
        if calorieDeficit > 650 {
            return .high
        } else if calorieDeficit > 300 {
            return .medium
        } else {
            return .low
        }
    }

    private static func adjustmentProfile(
        for food: Food,
        level: DeficitLevel
    ) -> AdjustmentProfile {
        if isFatDenseFood(food) {
            switch level {
            case .low:
                return AdjustmentProfile(step: 5, maxGrams: 25)
            case .medium:
                return AdjustmentProfile(step: 10, maxGrams: 30)
            case .high:
                return AdjustmentProfile(step: 10, maxGrams: 35)
            }
        }

        if isNutOrSeed(food) {
            switch level {
            case .low:
                return AdjustmentProfile(step: 10, maxGrams: 40)
            case .medium:
                return AdjustmentProfile(step: 10, maxGrams: 45)
            case .high:
                return AdjustmentProfile(step: 15, maxGrams: 50)
            }
        }

        if isProteinFood(food) {
            switch level {
            case .low:
                return AdjustmentProfile(step: 25, maxGrams: 300)
            case .medium:
                return AdjustmentProfile(step: 50, maxGrams: 360)
            case .high:
                return AdjustmentProfile(step: 75, maxGrams: 420)
            }
        }

        if isCarbFood(food) {
            switch level {
            case .low:
                return AdjustmentProfile(step: 25, maxGrams: 340)
            case .medium:
                return AdjustmentProfile(step: 50, maxGrams: 420)
            case .high:
                return AdjustmentProfile(step: 75, maxGrams: 500)
            }
        }

        if isFruitFood(food) {
            switch level {
            case .low:
                return AdjustmentProfile(step: 25, maxGrams: 220)
            case .medium:
                return AdjustmentProfile(step: 25, maxGrams: 260)
            case .high:
                return AdjustmentProfile(step: 50, maxGrams: 300)
            }
        }

        if isVegetableFood(food) {
            switch level {
            case .low:
                return AdjustmentProfile(step: 25, maxGrams: 250)
            case .medium:
                return AdjustmentProfile(step: 25, maxGrams: 280)
            case .high:
                return AdjustmentProfile(step: 50, maxGrams: 320)
            }
        }

        switch level {
        case .low:
            return AdjustmentProfile(step: 25, maxGrams: 260)
        case .medium:
            return AdjustmentProfile(step: 50, maxGrams: 320)
        case .high:
            return AdjustmentProfile(step: 50, maxGrams: 360)
        }
    }

    private static func isFatDenseFood(_ food: Food) -> Bool {
        if food.tags.contains("fat") || food.id.contains("oil") || food.id.contains("butter") {
            return true
        }

        return food.macrosPer100g.fat >= 60
    }

    private static func isNutOrSeed(_ food: Food) -> Bool {
        if food.tags.contains("nut") || food.tags.contains("seed") {
            return true
        }

        return food.groups.contains("nuts") || food.groups.contains("seeds")
    }

    private static func isProteinFood(_ food: Food) -> Bool {
        if food.tags.contains("meat") || food.tags.contains("egg") || food.tags.contains("seafood") {
            return true
        }

        if food.groups.contains("poultry")
            || food.groups.contains("seafood")
            || food.groups.contains("red_meat")
            || food.groups.contains("eggs")
            || food.groups.contains("protein_alt") {
            return true
        }

        return food.macrosPer100g.protein >= 10 && food.macrosPer100g.carbs < 12
    }

    private static func isCarbFood(_ food: Food) -> Bool {
        if food.tags.contains("grain") || food.tags.contains("legume") {
            return true
        }

        if food.groups.contains("grain") || food.groups.contains("legumes") {
            return true
        }

        return food.macrosPer100g.carbs >= 15 && food.macrosPer100g.fat < 8
    }

    private static func isFruitFood(_ food: Food) -> Bool {
        if food.tags.contains("fruit") {
            return true
        }

        return food.groups.contains("fruit")
            || food.groups.contains("berries")
            || food.groups.contains("citrus")
    }

    private static func isVegetableFood(_ food: Food) -> Bool {
        if food.tags.contains("vegetable") {
            return true
        }

        return food.groups.contains("vegetable")
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
