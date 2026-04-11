import Foundation

enum DayPlanCalorieTopUpService {
    static func topUpIfNeeded(
        dayPlan: DayPlan,
        goal: NutritionGoal?,
        allowedRecipes: [Recipe],
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus
    ) -> DayPlan {
        guard let goal else {
            return dayPlan
        }

        var meals = dayPlan.meals.sorted {
            mealOrder($0.type) < mealOrder($1.type)
        }

        let currentSummary = summarize(meals: meals, foodsById: foodsById)
        let calorieDeficit = Double(goal.targetCalories) - currentSummary.macros.calories

        guard calorieDeficit > 220 else {
            return DayPlan(meals: meals)
        }

        let hasSnack = meals.contains(where: { $0.type == .snack })
        let maxAdditionalSnacks = hasSnack ? 1 : 2
        var addedSnacks = 0

        while addedSnacks < maxAdditionalSnacks {
            let summaryBeforeAdd = summarize(meals: meals, foodsById: foodsById)
            let remainingCalories = Double(goal.targetCalories) - summaryBeforeAdd.macros.calories

            guard remainingCalories > 180 else {
                break
            }

            let usedRecipeIds = Set(meals.map { $0.recipe.id })
            let snackCandidates = allowedRecipes.filter {
                $0.tags.contains("snack") && !usedRecipeIds.contains($0.id)
            }

            guard let bestSnack = bestSnackRecipe(
                from: snackCandidates,
                currentSummary: summaryBeforeAdd,
                goal: goal,
                foodsById: foodsById,
                nutrientFocus: nutrientFocus
            ) else {
                break
            }

            meals.append(
                PlannedMeal(
                    type: .snack,
                    recipe: bestSnack
                )
            )
            addedSnacks += 1

            let afterSnackPlan = DayPlan(meals: meals)
            let afterPortionOptimization = DayPlanPortionOptimizer.optimize(
                dayPlan: afterSnackPlan,
                goal: goal,
                foodsById: foodsById,
                nutrientFocus: nutrientFocus
            )

            meals = afterPortionOptimization.meals.sorted {
                mealOrder($0.type) < mealOrder($1.type)
            }
        }

        return DayPlan(meals: meals)
    }

    private static func bestSnackRecipe(
        from recipes: [Recipe],
        currentSummary: NutritionSummary,
        goal: NutritionGoal,
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus
    ) -> Recipe? {
        guard !recipes.isEmpty else { return nil }

        let remainingCalories = max(Double(goal.targetCalories) - currentSummary.macros.calories, 0)
        let remainingProtein = max(Double(goal.proteinGrams) - currentSummary.macros.protein, 0)
        let remainingFat = max(Double(goal.fatGrams) - currentSummary.macros.fat, 0)
        let remainingCarbs = max(Double(goal.carbsGrams) - currentSummary.macros.carbs, 0)

        let targetSnackCalories = min(max(remainingCalories, 220), 420)

        return recipes.max { left, right in
            snackScore(
                recipe: left,
                targetSnackCalories: targetSnackCalories,
                remainingCalories: remainingCalories,
                remainingProtein: remainingProtein,
                remainingFat: remainingFat,
                remainingCarbs: remainingCarbs,
                foodsById: foodsById,
                nutrientFocus: nutrientFocus
            ) < snackScore(
                recipe: right,
                targetSnackCalories: targetSnackCalories,
                remainingCalories: remainingCalories,
                remainingProtein: remainingProtein,
                remainingFat: remainingFat,
                remainingCarbs: remainingCarbs,
                foodsById: foodsById,
                nutrientFocus: nutrientFocus
            )
        }
    }

    private static func snackScore(
        recipe: Recipe,
        targetSnackCalories: Double,
        remainingCalories: Double,
        remainingProtein: Double,
        remainingFat: Double,
        remainingCarbs: Double,
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus
    ) -> Double {
        let summary = NutritionCalculator.summarize(
            ingredients: recipe.ingredients,
            foodsById: foodsById
        )

        let calories = summary.macros.calories
        let protein = summary.macros.protein
        let fat = summary.macros.fat
        let carbs = summary.macros.carbs
        let iron = summary.nutrients["iron", default: 0]

        let calorieScore = 100.0 - min(
            abs(targetSnackCalories - calories) / max(targetSnackCalories, 200.0) * 100.0,
            100.0
        )

        let proteinScore: Double
        if remainingProtein > 0 {
            proteinScore = min(protein / max(remainingProtein, 12.0), 1.0) * 24.0
        } else {
            proteinScore = min(protein / 18.0, 1.0) * 8.0
        }

        let fatScore: Double
        if remainingFat > 0 {
            fatScore = min(fat / max(remainingFat, 8.0), 1.0) * 12.0
        } else {
            fatScore = min(fat / 12.0, 1.0) * 4.0
        }

        let carbsScore: Double
        if remainingCarbs > 0 {
            carbsScore = min(carbs / max(remainingCarbs, 15.0), 1.0) * 14.0
        } else {
            carbsScore = min(carbs / 20.0, 1.0) * 4.0
        }

        let overshootPenalty: Double
        if calories > remainingCalories + 220 {
            overshootPenalty = min((calories - remainingCalories - 220) / 80.0 * 12.0, 20.0)
        } else {
            overshootPenalty = 0
        }

        let nutrientBonus: Double
        switch nutrientFocus {
        case .none:
            nutrientBonus = 0
        case .iron:
            nutrientBonus = min(iron * 2.0, 8.0)
        }

        return calorieScore + proteinScore + fatScore + carbsScore + nutrientBonus - overshootPenalty
    }

    private static func summarize(
        meals: [PlannedMeal],
        foodsById: [String: Food]
    ) -> NutritionSummary {
        var totalMacros = Macros.zero
        var totalNutrients: [String: Double] = [:]

        for meal in meals {
            let summary = NutritionCalculator.summarize(
                ingredients: meal.recipe.ingredients,
                foodsById: foodsById
            )

            totalMacros = totalMacros + summary.macros

            for (key, value) in summary.nutrients {
                totalNutrients[key, default: 0] += value
            }
        }

        return NutritionSummary(
            macros: totalMacros,
            nutrients: totalNutrients
        )
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
