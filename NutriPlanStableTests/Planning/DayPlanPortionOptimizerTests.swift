import XCTest
@testable import NutriPlan

final class DayPlanPortionOptimizerTests: XCTestCase {

    func testOptimizeReturnsSamePlanWhenGoalIsNil() {
        let foodsById = makeFoods()

        let recipe = Recipe(
            id: "oatmeal",
            name: "Овсянка",
            ingredients: [
                RecipeIngredient(foodId: "oats", grams: 50)
            ],
            cookTimeMinutes: 10,
            tags: ["breakfast"],
            isModified: false
        )

        let dayPlan = DayPlan(
            meals: [
                PlannedMeal(type: .breakfast, recipe: recipe)
            ]
        )

        let result = DayPlanPortionOptimizer.optimize(
            dayPlan: dayPlan,
            goal: nil,
            foodsById: foodsById,
            nutrientFocus: .none
        )

        XCTAssertEqual(result, dayPlan)
    }

    func testOptimizeIncreasesIngredientGramsWhenPlanHasStrongCalorieDeficit() {
        let foodsById = makeFoods()

        let recipe = Recipe(
            id: "oatmeal",
            name: "Овсянка",
            ingredients: [
                RecipeIngredient(foodId: "oats", grams: 50)
            ],
            cookTimeMinutes: 10,
            tags: ["breakfast"],
            isModified: false
        )

        let dayPlan = DayPlan(
            meals: [
                PlannedMeal(type: .breakfast, recipe: recipe)
            ]
        )

        let goal = NutritionGoal(
            targetCalories: 1600,
            proteinGrams: 70,
            fatGrams: 45,
            carbsGrams: 200
        )

        let result = DayPlanPortionOptimizer.optimize(
            dayPlan: dayPlan,
            goal: goal,
            foodsById: foodsById,
            nutrientFocus: .none
        )

        let originalGrams = dayPlan.meals[0].recipe.ingredients[0].grams
        let optimizedGrams = result.meals[0].recipe.ingredients[0].grams

        XCTAssertGreaterThan(optimizedGrams, originalGrams)
    }

    func testOptimizeSortsMealsByMealTypeOrder() {
        let foodsById = makeFoods()

        let breakfastRecipe = Recipe(
            id: "breakfast_recipe",
            name: "Завтрак",
            ingredients: [
                RecipeIngredient(foodId: "oats", grams: 60)
            ],
            cookTimeMinutes: 10,
            tags: ["breakfast"],
            isModified: false
        )

        let dinnerRecipe = Recipe(
            id: "dinner_recipe",
            name: "Ужин",
            ingredients: [
                RecipeIngredient(foodId: "chicken", grams: 120)
            ],
            cookTimeMinutes: 20,
            tags: ["dinner"],
            isModified: false
        )

        let snackRecipe = Recipe(
            id: "snack_recipe",
            name: "Перекус",
            ingredients: [
                RecipeIngredient(foodId: "banana", grams: 100)
            ],
            cookTimeMinutes: nil,
            tags: ["snack"],
            isModified: false
        )

        let unsortedPlan = DayPlan(
            meals: [
                PlannedMeal(type: .snack, recipe: snackRecipe),
                PlannedMeal(type: .dinner, recipe: dinnerRecipe),
                PlannedMeal(type: .breakfast, recipe: breakfastRecipe)
            ]
        )

        let goal = NutritionGoal(
            targetCalories: 1800,
            proteinGrams: 90,
            fatGrams: 55,
            carbsGrams: 210
        )

        let result = DayPlanPortionOptimizer.optimize(
            dayPlan: unsortedPlan,
            goal: goal,
            foodsById: foodsById,
            nutrientFocus: .none
        )

        let mealTypes = result.meals.map(\.type)
        XCTAssertEqual(mealTypes, [.breakfast, .dinner, .snack])
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
                tags: ["fruit"],
                groups: ["fruit"],
                allergens: []
            ),
            "chicken": Food(
                id: "chicken",
                name: "Курица",
                macrosPer100g: Macros(calories: 165, protein: 31, fat: 3.6, carbs: 0),
                nutrientsPer100g: [:],
                tags: ["meat"],
                groups: ["poultry"],
                allergens: []
            )
        ]
    }
}
