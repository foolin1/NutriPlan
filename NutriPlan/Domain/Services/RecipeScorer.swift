import Foundation

struct RecipeScoreBreakdown: Hashable {
    let totalScore: Double

    let mealTargetCalories: Double
    let mealTargetProtein: Double
    let mealTargetFat: Double
    let mealTargetCarbs: Double

    let actualCalories: Double
    let actualProtein: Double
    let actualFat: Double
    let actualCarbs: Double

    let caloriePenalty: Double
    let proteinPenalty: Double
    let fatPenalty: Double
    let carbsPenalty: Double

    let nutrientBonus: Double
    let tagBonus: Double

    let ironAmount: Double
    let focusedNutrientAmount: Double
}

enum RecipeScorer {
    static func evaluate(
        recipe: Recipe,
        mealType: MealType,
        goal: NutritionGoal?,
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus
    ) -> RecipeScoreBreakdown {
        let summary = NutritionCalculator.summarize(
            ingredients: recipe.ingredients,
            foodsById: foodsById
        )

        let actualCalories = summary.macros.calories
        let actualProtein = summary.macros.protein
        let actualFat = summary.macros.fat
        let actualCarbs = summary.macros.carbs

        let ironAmount = summary.nutrients["iron", default: 0]
        let focusedNutrientAmount = NutrientCatalog.focusedAmount(
            in: summary.nutrients,
            for: nutrientFocus
        )

        let share = mealShare(for: mealType)

        let mealTargetCalories: Double
        let mealTargetProtein: Double
        let mealTargetFat: Double
        let mealTargetCarbs: Double

        if let goal {
            mealTargetCalories = Double(goal.targetCalories) * share
            mealTargetProtein = Double(goal.proteinGrams) * share
            mealTargetFat = Double(goal.fatGrams) * share
            mealTargetCarbs = Double(goal.carbsGrams) * share
        } else {
            mealTargetCalories = actualCalories
            mealTargetProtein = actualProtein
            mealTargetFat = actualFat
            mealTargetCarbs = actualCarbs
        }

        let caloriePenalty = relativePenalty(
            actual: actualCalories,
            target: mealTargetCalories,
            fallback: 150
        ) * 45

        let proteinPenalty = relativePenalty(
            actual: actualProtein,
            target: mealTargetProtein,
            fallback: 10
        ) * 25

        let fatPenalty = relativePenalty(
            actual: actualFat,
            target: mealTargetFat,
            fallback: 8
        ) * 15

        let carbsPenalty = relativePenalty(
            actual: actualCarbs,
            target: mealTargetCarbs,
            fallback: 15
        ) * 15

        let nutrientBonus = NutrientCatalog.recipeBonus(
            for: nutrientFocus,
            amount: focusedNutrientAmount
        )

        let tagBonus = recipe.tags.contains(mealTag(for: mealType)) ? 8.0 : 0.0

        let totalScore = max(
            0,
            min(
                100,
                100
                    - caloriePenalty
                    - proteinPenalty
                    - fatPenalty
                    - carbsPenalty
                    + nutrientBonus
                    + tagBonus
            )
        )

        return RecipeScoreBreakdown(
            totalScore: totalScore,
            mealTargetCalories: mealTargetCalories,
            mealTargetProtein: mealTargetProtein,
            mealTargetFat: mealTargetFat,
            mealTargetCarbs: mealTargetCarbs,
            actualCalories: actualCalories,
            actualProtein: actualProtein,
            actualFat: actualFat,
            actualCarbs: actualCarbs,
            caloriePenalty: caloriePenalty,
            proteinPenalty: proteinPenalty,
            fatPenalty: fatPenalty,
            carbsPenalty: carbsPenalty,
            nutrientBonus: nutrientBonus,
            tagBonus: tagBonus,
            ironAmount: ironAmount,
            focusedNutrientAmount: focusedNutrientAmount
        )
    }

    static func mealTag(for mealType: MealType) -> String {
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

    private static func mealShare(for mealType: MealType) -> Double {
        switch mealType {
        case .breakfast:
            return 0.25
        case .lunch:
            return 0.35
        case .dinner:
            return 0.30
        case .snack:
            return 0.10
        }
    }

    private static func relativePenalty(
        actual: Double,
        target: Double,
        fallback: Double
    ) -> Double {
        let denominator = max(target, fallback)
        return abs(actual - target) / denominator
    }
}
