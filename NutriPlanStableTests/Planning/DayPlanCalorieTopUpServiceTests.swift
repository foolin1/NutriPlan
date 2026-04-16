import XCTest
@testable import NutriPlan

final class DayPlanCalorieTopUpServiceTests: XCTestCase {

    func testTopUpAddsSnackWhenCaloriesAreFarBelowGoal() {
        let foodsById = makeFoods()

        let breakfastRecipe = Recipe(
            id: "oatmeal",
            name: "Овсянка",
            ingredients: [
                RecipeIngredient(foodId: "oats", grams: 40)
            ],
            cookTimeMinutes: 10,
            tags: ["breakfast"],
            isModified: false
        )

        let snackRecipe = Recipe(
            id: "banana_snack",
            name: "Банан",
            ingredients: [
                RecipeIngredient(foodId: "banana", grams: 120)
            ],
            cookTimeMinutes: nil,
            tags: ["snack"],
            isModified: false
        )

        let dayPlan = DayPlan(
            meals: [
                PlannedMeal(type: .breakfast, recipe: breakfastRecipe)
            ]
        )

        let goal = NutritionGoal(
            targetCalories: 1200,
            proteinGrams: 60,
            fatGrams: 40,
            carbsGrams: 150
        )

        let result = DayPlanCalorieTopUpService.topUpIfNeeded(
            dayPlan: dayPlan,
            goal: goal,
            allowedRecipes: [breakfastRecipe, snackRecipe],
            foodsById: foodsById,
            nutrientFocus: .none
        )

        XCTAssertGreaterThan(result.meals.count, dayPlan.meals.count)
        XCTAssertTrue(result.meals.contains(where: { $0.type == .snack }))
        XCTAssertTrue(result.meals.contains(where: { $0.recipe.id == "banana_snack" }))
    }

    func testTopUpDoesNothingWhenGoalIsNil() {
        let foodsById = makeFoods()

        let breakfastRecipe = Recipe(
            id: "oatmeal",
            name: "Овсянка",
            ingredients: [
                RecipeIngredient(foodId: "oats", grams: 40)
            ],
            cookTimeMinutes: 10,
            tags: ["breakfast"],
            isModified: false
        )

        let dayPlan = DayPlan(
            meals: [
                PlannedMeal(type: .breakfast, recipe: breakfastRecipe)
            ]
        )

        let result = DayPlanCalorieTopUpService.topUpIfNeeded(
            dayPlan: dayPlan,
            goal: nil,
            allowedRecipes: [breakfastRecipe],
            foodsById: foodsById,
            nutrientFocus: .none
        )

        XCTAssertEqual(result.meals.count, dayPlan.meals.count)
        XCTAssertEqual(result.meals.first?.recipe.id, "oatmeal")
    }

    func testTopUpDoesNothingWhenCaloriesAreAlreadyCloseEnough() {
        let foodsById: [String: Food] = [
            "oats": Food(
                id: "oats",
                name: "Овсянка",
                macrosPer100g: Macros(calories: 370, protein: 13, fat: 7, carbs: 60),
                nutrientsPer100g: [:],
                tags: ["grain"],
                groups: ["grain"],
                allergens: []
            )
        ]

        let breakfastRecipe = Recipe(
            id: "big_oatmeal",
            name: "Большая овсянка",
            ingredients: [
                RecipeIngredient(foodId: "oats", grams: 270)
            ],
            cookTimeMinutes: 10,
            tags: ["breakfast"],
            isModified: false
        )

        let snackRecipe = Recipe(
            id: "banana_snack",
            name: "Банан",
            ingredients: [
                RecipeIngredient(foodId: "banana", grams: 120)
            ],
            cookTimeMinutes: nil,
            tags: ["snack"],
            isModified: false
        )

        let dayPlan = DayPlan(
            meals: [
                PlannedMeal(type: .breakfast, recipe: breakfastRecipe)
            ]
        )

        let goal = NutritionGoal(
            targetCalories: 1150,
            proteinGrams: 50,
            fatGrams: 35,
            carbsGrams: 130
        )

        let result = DayPlanCalorieTopUpService.topUpIfNeeded(
            dayPlan: dayPlan,
            goal: goal,
            allowedRecipes: [breakfastRecipe, snackRecipe],
            foodsById: foodsById,
            nutrientFocus: .none
        )

        XCTAssertEqual(result.meals.count, dayPlan.meals.count)
        XCTAssertFalse(result.meals.contains(where: { $0.type == .snack }))
    }

    private func makeFoods() -> [String: Food] {
        [
            "oats": Food(
                id: "oats",
                name: "Овсянка",
                macrosPer100g: Macros(calories: 370, protein: 13, fat: 7, carbs: 60),
                nutrientsPer100g: [:],
                tags: ["grain"],
                groups: ["grain"],
                allergens: []
            ),
            "banana": Food(
                id: "banana",
                name: "Банан",
                macrosPer100g: Macros(calories: 89, protein: 1.1, fat: 0.3, carbs: 23),
                nutrientsPer100g: [:],
                tags: ["fruit", "snack"],
                groups: ["fruit"],
                allergens: []
            )
        ]
    }
}
