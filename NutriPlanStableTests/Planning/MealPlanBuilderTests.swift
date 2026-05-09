import XCTest
@testable import NutriPlan

final class MealPlanBuilderTests: XCTestCase {

    func testFilteredAllowedRecipesExcludesRecipeWithForbiddenAllergen() {
        let foodsById = makeFoods()
        let safeRecipe = makeRecipe(
            id: "safe_oatmeal",
            name: "Овсянка",
            ingredients: [
                RecipeIngredient(foodId: "oats", grams: 60)
            ],
            tags: ["breakfast"]
        )
        let forbiddenRecipe = makeRecipe(
            id: "shrimp_lunch",
            name: "Креветки с рисом",
            ingredients: [
                RecipeIngredient(foodId: "shrimp", grams: 120),
                RecipeIngredient(foodId: "rice", grams: 100)
            ],
            tags: ["lunch"]
        )

        let result = MealPlanBuilder.filteredAllowedRecipes(
            recipes: [safeRecipe, forbiddenRecipe],
            foodsById: foodsById,
            excludedAllergens: ["shellfish"],
            excludedProducts: [],
            excludedGroups: []
        )

        XCTAssertEqual(result.map(\.id), ["safe_oatmeal"])
    }

    func testFilteredAllowedRecipesExcludesRecipeWithForbiddenGroup() {
        let foodsById = makeFoods()
        let dairyRecipe = makeRecipe(
            id: "yogurt_snack",
            name: "Йогурт с бананом",
            ingredients: [
                RecipeIngredient(foodId: "yogurt", grams: 150),
                RecipeIngredient(foodId: "banana", grams: 100)
            ],
            tags: ["snack"]
        )
        let fruitRecipe = makeRecipe(
            id: "banana_snack",
            name: "Банан",
            ingredients: [
                RecipeIngredient(foodId: "banana", grams: 120)
            ],
            tags: ["snack"]
        )

        let result = MealPlanBuilder.filteredAllowedRecipes(
            recipes: [dairyRecipe, fruitRecipe],
            foodsById: foodsById,
            excludedAllergens: [],
            excludedProducts: [],
            excludedGroups: ["dairy"]
        )

        XCTAssertEqual(result.map(\.id), ["banana_snack"])
    }

    func testFilteredAllowedRecipesExcludesRecipeByProductNameSubstring() {
        let foodsById = makeFoods()
        let chickenRecipe = makeRecipe(
            id: "chicken_lunch",
            name: "Курица с рисом",
            ingredients: [
                RecipeIngredient(foodId: "chicken", grams: 150),
                RecipeIngredient(foodId: "rice", grams: 100)
            ],
            tags: ["lunch"]
        )
        let turkeyRecipe = makeRecipe(
            id: "turkey_lunch",
            name: "Индейка с рисом",
            ingredients: [
                RecipeIngredient(foodId: "turkey", grams: 150),
                RecipeIngredient(foodId: "rice", grams: 100)
            ],
            tags: ["lunch"]
        )

        let result = MealPlanBuilder.filteredAllowedRecipes(
            recipes: [chickenRecipe, turkeyRecipe],
            foodsById: foodsById,
            excludedAllergens: [],
            excludedProducts: ["курин"],
            excludedGroups: []
        )

        XCTAssertEqual(result.map(\.id), ["turkey_lunch"])
    }

    func testFilteredAllowedRecipesKeepsRecipeWhenUnknownFoodIsMissingFromCatalog() {
        let foodsById = makeFoods()
        let recipe = makeRecipe(
            id: "custom_recipe",
            name: "Пользовательское блюдо",
            ingredients: [
                RecipeIngredient(foodId: "unknown_food", grams: 100)
            ],
            tags: ["dinner"]
        )

        let result = MealPlanBuilder.filteredAllowedRecipes(
            recipes: [recipe],
            foodsById: foodsById,
            excludedAllergens: ["nuts"],
            excludedProducts: ["арахис"],
            excludedGroups: ["nuts"]
        )

        XCTAssertEqual(result.map(\.id), ["custom_recipe"])
    }

    func testBuildCandidatePoolsUsesPreferredMealTagsWhenAvailable() {
        let foodsById = makeFoods()
        let breakfastRecipe = makeRecipe(
            id: "breakfast_oats",
            name: "Овсянка",
            ingredients: [
                RecipeIngredient(foodId: "oats", grams: 60)
            ],
            tags: ["breakfast"]
        )
        let lunchRecipe = makeRecipe(
            id: "lunch_chicken",
            name: "Курица с рисом",
            ingredients: [
                RecipeIngredient(foodId: "chicken", grams: 150),
                RecipeIngredient(foodId: "rice", grams: 100)
            ],
            tags: ["lunch"]
        )
        let dinnerRecipe = makeRecipe(
            id: "dinner_turkey",
            name: "Индейка с брокколи",
            ingredients: [
                RecipeIngredient(foodId: "turkey", grams: 150),
                RecipeIngredient(foodId: "broccoli", grams: 150)
            ],
            tags: ["dinner"]
        )

        let pools = MealPlanBuilder.buildCandidatePools(
            goal: nil,
            recipes: [breakfastRecipe, lunchRecipe, dinnerRecipe],
            foodsById: foodsById,
            nutrientFocus: .none
        )

        XCTAssertEqual(pools[.breakfast]?.map(\.id), ["breakfast_oats"])
        XCTAssertEqual(pools[.lunch]?.map(\.id), ["lunch_chicken"])
        XCTAssertEqual(pools[.dinner]?.map(\.id), ["dinner_turkey"])
    }

    func testBuildCandidatePoolsFallsBackToAllAllowedRecipesWhenMealTagIsMissing() {
        let foodsById = makeFoods()
        let breakfastRecipe = makeRecipe(
            id: "breakfast_oats",
            name: "Овсянка",
            ingredients: [
                RecipeIngredient(foodId: "oats", grams: 60)
            ],
            tags: ["breakfast"]
        )
        let lunchRecipe = makeRecipe(
            id: "lunch_chicken",
            name: "Курица с рисом",
            ingredients: [
                RecipeIngredient(foodId: "chicken", grams: 150),
                RecipeIngredient(foodId: "rice", grams: 100)
            ],
            tags: ["lunch"]
        )

        let pools = MealPlanBuilder.buildCandidatePools(
            goal: nil,
            recipes: [breakfastRecipe, lunchRecipe],
            foodsById: foodsById,
            nutrientFocus: .none
        )

        let snackIds = Set(pools[.snack]?.map(\.id) ?? [])

        XCTAssertEqual(snackIds, ["breakfast_oats", "lunch_chicken"])
    }

    func testBuildCandidatePoolsLimitsCandidatesToEightPerMealType() {
        let foodsById = makeFoods()
        let recipes = (1...12).map { index in
            makeRecipe(
                id: "breakfast_\(index)",
                name: "Завтрак \(index)",
                ingredients: [
                    RecipeIngredient(foodId: "oats", grams: Double(40 + index))
                ],
                tags: ["breakfast"]
            )
        }

        let pools = MealPlanBuilder.buildCandidatePools(
            goal: nil,
            recipes: recipes,
            foodsById: foodsById,
            nutrientFocus: .none
        )

        XCTAssertEqual(pools[.breakfast]?.count, 8)
    }

    func testBuildDayPlanReturnsEmptyWhenAllRecipesAreExcluded() {
        let foodsById = makeFoods()
        let shrimpRecipe = makeRecipe(
            id: "shrimp_lunch",
            name: "Креветки с рисом",
            ingredients: [
                RecipeIngredient(foodId: "shrimp", grams: 120),
                RecipeIngredient(foodId: "rice", grams: 100)
            ],
            tags: ["lunch"]
        )

        let plan = MealPlanBuilder.buildDayPlan(
            goal: NutritionGoal(
                targetCalories: 1800,
                proteinGrams: 100,
                fatGrams: 55,
                carbsGrams: 220
            ),
            recipes: [shrimpRecipe],
            foodsById: foodsById,
            excludedAllergens: ["shellfish"],
            excludedProducts: [],
            excludedGroups: [],
            nutrientFocus: .none
        )

        XCTAssertTrue(plan.meals.isEmpty)
    }

    private func makeRecipe(
        id: String,
        name: String,
        ingredients: [RecipeIngredient],
        tags: Set<String>
    ) -> Recipe {
        Recipe(
            id: id,
            name: name,
            ingredients: ingredients,
            cookTimeMinutes: 15,
            tags: tags,
            isModified: false
        )
    }

    private func makeFoods() -> [String: Food] {
        let foods = [
            Food(
                id: "oats",
                name: "Овсянка",
                macrosPer100g: Macros(calories: 370, protein: 13, fat: 7, carbs: 60),
                nutrientsPer100g: ["iron": 4.0],
                tags: ["grain"],
                groups: ["grain"],
                allergens: []
            ),
            Food(
                id: "rice",
                name: "Рис",
                macrosPer100g: Macros(calories: 130, protein: 2.7, fat: 0.3, carbs: 28),
                nutrientsPer100g: [:],
                tags: ["grain"],
                groups: ["grain"],
                allergens: []
            ),
            Food(
                id: "chicken",
                name: "Куриная грудка",
                macrosPer100g: Macros(calories: 165, protein: 31, fat: 3.6, carbs: 0),
                nutrientsPer100g: [:],
                tags: ["meat", "high_protein"],
                groups: ["poultry"],
                allergens: []
            ),
            Food(
                id: "turkey",
                name: "Филе индейки",
                macrosPer100g: Macros(calories: 135, protein: 29, fat: 1.6, carbs: 0),
                nutrientsPer100g: [:],
                tags: ["meat", "high_protein"],
                groups: ["poultry"],
                allergens: []
            ),
            Food(
                id: "shrimp",
                name: "Креветки",
                macrosPer100g: Macros(calories: 99, protein: 24, fat: 0.3, carbs: 0.2),
                nutrientsPer100g: [:],
                tags: ["seafood"],
                groups: ["seafood"],
                allergens: ["shellfish"]
            ),
            Food(
                id: "banana",
                name: "Банан",
                macrosPer100g: Macros(calories: 89, protein: 1.1, fat: 0.3, carbs: 23),
                nutrientsPer100g: ["vitamin_c": 8.7],
                tags: ["fruit"],
                groups: ["fruit"],
                allergens: []
            ),
            Food(
                id: "yogurt",
                name: "Йогурт",
                macrosPer100g: Macros(calories: 59, protein: 3.5, fat: 3.3, carbs: 4.7),
                nutrientsPer100g: ["calcium": 120],
                tags: ["dairy"],
                groups: ["dairy"],
                allergens: ["milk"]
            ),
            Food(
                id: "broccoli",
                name: "Брокколи",
                macrosPer100g: Macros(calories: 35, protein: 2.8, fat: 0.4, carbs: 7),
                nutrientsPer100g: ["vitamin_c": 89],
                tags: ["vegetable"],
                groups: ["vegetable"],
                allergens: []
            )
        ]

        return Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })
    }
}
