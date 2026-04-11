import Foundation
import Testing
@testable import NutriPlan

struct MealPlanRestrictionsTests {
    @Test("Исключённые аллергены убирают рецепты с соответствующими продуктами")
    func excludedAllergensRemoveMatchingRecipes() {
        let allowed = MealPlanBuilder.filteredAllowedRecipes(
            recipes: TestDataFactory.highCalorieRecipes,
            foodsById: TestDataFactory.foodsById,
            excludedAllergens: ["lactose"],
            excludedProducts: [],
            excludedGroups: []
        )

        #expect(!allowed.isEmpty)
        #expect(allowed.count < TestDataFactory.highCalorieRecipes.count)

        let hasLactose = allowed.contains { recipe in
            recipe.ingredients.contains { ingredient in
                TestDataFactory.foodsById[ingredient.foodId]?
                    .allergens
                    .contains("lactose") == true
            }
        }

        #expect(hasLactose == false)
    }

    @Test("Исключённые продукты по названию или id не попадают в допустимые рецепты")
    func excludedProductsRemoveMatchingFoods() {
        let allowed = MealPlanBuilder.filteredAllowedRecipes(
            recipes: TestDataFactory.highCalorieRecipes,
            foodsById: TestDataFactory.foodsById,
            excludedAllergens: [],
            excludedProducts: ["banana"],
            excludedGroups: []
        )

        #expect(!allowed.isEmpty)

        let hasBanana = allowed.contains { recipe in
            recipe.ingredients.contains { ingredient in
                let food = TestDataFactory.foodsById[ingredient.foodId]
                let id = food?.id.lowercased() ?? ""
                let name = food?.name.lowercased() ?? ""
                return id.contains("banana") || name.contains("банан")
            }
        }

        #expect(hasBanana == false)
    }

    @Test("Исключённые группы продуктов убирают рецепты с такими ингредиентами")
    func excludedGroupsRemoveMatchingFoods() {
        let allowed = MealPlanBuilder.filteredAllowedRecipes(
            recipes: TestDataFactory.highCalorieRecipes,
            foodsById: TestDataFactory.foodsById,
            excludedAllergens: [],
            excludedProducts: [],
            excludedGroups: ["citrus"]
        )

        #expect(!allowed.isEmpty)

        let hasCitrus = allowed.contains { recipe in
            recipe.ingredients.contains { ingredient in
                TestDataFactory.foodsById[ingredient.foodId]?
                    .groups
                    .contains("citrus") == true
            }
        }

        #expect(hasCitrus == false)
    }
}
