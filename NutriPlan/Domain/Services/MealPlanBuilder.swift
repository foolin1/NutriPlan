import Foundation

enum MealPlanBuilder {
    static func buildDayPlan(
        goal: NutritionGoal?,
        recipes: [Recipe],
        foodsById: [String: Food],
        excludedAllergens: Set<String> = [],
        excludedProducts: Set<String> = [],
        excludedGroups: Set<String> = [],
        nutrientFocus: NutrientFocus = .none
    ) -> DayPlan {
        let allowedRecipes = recipes.filter {
            isRecipeAllowed(
                $0,
                foodsById: foodsById,
                excludedAllergens: excludedAllergens,
                excludedProducts: excludedProducts,
                excludedGroups: excludedGroups
            )
        }

        guard !allowedRecipes.isEmpty else {
            return .empty
        }

        // Для каждого приема пищи сначала отбираем локально лучшие рецепты,
        // а затем оптимизируем уже комбинацию всего дня.
        let candidateLimitPerMeal = 4
        var candidatePools: [MealType: [Recipe]] = [:]

        for mealType in MealType.allCases {
            let preferredTag = RecipeScorer.mealTag(for: mealType)

            let taggedRecipes = allowedRecipes.filter {
                $0.tags.contains(preferredTag)
            }

            let poolSource = taggedRecipes.isEmpty ? allowedRecipes : taggedRecipes

            let rankedRecipes = poolSource.sorted {
                let left = RecipeScorer.evaluate(
                    recipe: $0,
                    mealType: mealType,
                    goal: goal,
                    foodsById: foodsById,
                    nutrientFocus: nutrientFocus
                )

                let right = RecipeScorer.evaluate(
                    recipe: $1,
                    mealType: mealType,
                    goal: goal,
                    foodsById: foodsById,
                    nutrientFocus: nutrientFocus
                )

                return left.totalScore > right.totalScore
            }

            candidatePools[mealType] = Array(
                rankedRecipes.prefix(candidateLimitPerMeal)
            )
        }

        return DayPlanOptimizer.buildOptimizedDayPlan(
            goal: goal,
            candidatePools: candidatePools,
            foodsById: foodsById,
            nutrientFocus: nutrientFocus
        )
    }

    private static func isRecipeAllowed(
        _ recipe: Recipe,
        foodsById: [String: Food],
        excludedAllergens: Set<String>,
        excludedProducts: Set<String>,
        excludedGroups: Set<String>
    ) -> Bool {
        for ingredient in recipe.ingredients {
            guard let food = foodsById[ingredient.foodId] else {
                continue
            }

            if !excludedAllergens.isDisjoint(with: food.allergens) {
                return false
            }

            if !excludedGroups.isDisjoint(with: food.groups) {
                return false
            }

            let normalizedName = normalize(food.name)
            let normalizedId = normalize(food.id)

            for excluded in excludedProducts {
                if normalizedName.contains(excluded) || normalizedId.contains(excluded) {
                    return false
                }
            }
        }

        return true
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
