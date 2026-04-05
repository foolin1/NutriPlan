import Foundation

enum MealPlanBuilder {

    static func buildDayPlan(
        goal: NutritionGoal?,
        recipes: [Recipe],
        foodsById: [String: Food],
        excludedAllergens: Set<String> = [],
        nutrientFocus: NutrientFocus = .none
    ) -> DayPlan {

        let allowedRecipes = recipes.filter {
            isRecipeAllowed($0, foodsById: foodsById, excludedAllergens: excludedAllergens)
        }

        let breakfast = selectRecipe(
            from: allowedRecipes,
            requiredTag: "breakfast",
            fallbackStrategy: .lowestCalories,
            foodsById: foodsById,
            nutrientFocus: nutrientFocus
        )

        let lunch = selectRecipe(
            from: allowedRecipes,
            requiredTag: "lunch",
            fallbackStrategy: .highestCalories,
            foodsById: foodsById,
            nutrientFocus: nutrientFocus
        )

        let dinner = selectRecipe(
            from: allowedRecipes,
            requiredTag: "dinner",
            fallbackStrategy: .highestCalories,
            foodsById: foodsById,
            nutrientFocus: nutrientFocus
        )

        let snack = selectRecipe(
            from: allowedRecipes,
            requiredTag: "snack",
            fallbackStrategy: .lowestCalories,
            foodsById: foodsById,
            nutrientFocus: nutrientFocus
        )

        var meals: [PlannedMeal] = []

        if let breakfast {
            meals.append(PlannedMeal(type: .breakfast, recipe: breakfast))
        }
        if let lunch {
            meals.append(PlannedMeal(type: .lunch, recipe: lunch))
        }
        if let dinner {
            meals.append(PlannedMeal(type: .dinner, recipe: dinner))
        }
        if let snack {
            meals.append(PlannedMeal(type: .snack, recipe: snack))
        }

        return DayPlan(meals: meals)
    }

    private enum FallbackStrategy {
        case lowestCalories
        case highestCalories
    }

    private static func selectRecipe(
        from recipes: [Recipe],
        requiredTag: String,
        fallbackStrategy: FallbackStrategy,
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus
    ) -> Recipe? {

        let tagged = recipes.filter { $0.tags.contains(requiredTag) }

        if let bestTagged = selectBest(
            from: tagged,
            strategy: fallbackStrategy,
            foodsById: foodsById,
            nutrientFocus: nutrientFocus
        ) {
            return bestTagged
        }

        return selectBest(
            from: recipes,
            strategy: fallbackStrategy,
            foodsById: foodsById,
            nutrientFocus: nutrientFocus
        )
    }

    private static func selectBest(
        from recipes: [Recipe],
        strategy: FallbackStrategy,
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus
    ) -> Recipe? {

        guard !recipes.isEmpty else { return nil }

        return recipes.max {
            score(
                for: $0,
                strategy: strategy,
                foodsById: foodsById,
                nutrientFocus: nutrientFocus
            ) < score(
                for: $1,
                strategy: strategy,
                foodsById: foodsById,
                nutrientFocus: nutrientFocus
            )
        }
    }

    private static func score(
        for recipe: Recipe,
        strategy: FallbackStrategy,
        foodsById: [String: Food],
        nutrientFocus: NutrientFocus
    ) -> Double {

        let calories = totalCalories(for: recipe, foodsById: foodsById)
        let iron = nutrientAmount(for: recipe, nutrientId: "iron", foodsById: foodsById)

        let calorieBase: Double
        switch strategy {
        case .lowestCalories:
            calorieBase = -calories
        case .highestCalories:
            calorieBase = calories
        }

        let nutrientBonus: Double
        switch nutrientFocus {
        case .none:
            nutrientBonus = 0
        case .iron:
            nutrientBonus = iron * 120.0
        }

        return calorieBase + nutrientBonus
    }

    private static func totalCalories(for recipe: Recipe, foodsById: [String: Food]) -> Double {
        let summary = NutritionCalculator.summarize(
            ingredients: recipe.ingredients,
            foodsById: foodsById
        )
        return summary.macros.calories
    }

    private static func nutrientAmount(
        for recipe: Recipe,
        nutrientId: String,
        foodsById: [String: Food]
    ) -> Double {
        let summary = NutritionCalculator.summarize(
            ingredients: recipe.ingredients,
            foodsById: foodsById
        )
        return summary.nutrients[nutrientId, default: 0]
    }

    private static func isRecipeAllowed(
        _ recipe: Recipe,
        foodsById: [String: Food],
        excludedAllergens: Set<String>
    ) -> Bool {

        for ingredient in recipe.ingredients {
            guard let food = foodsById[ingredient.foodId] else { continue }
            if !excludedAllergens.isDisjoint(with: food.allergens) {
                return false
            }
        }

        return true
    }
}
