import XCTest
@testable import NutriPlan

final class NutritionCalculatorTests: XCTestCase {

    func testSummarizeCalculatesMacrosForMultipleIngredients() throws {
        let foodsById: [String: Food] = [
            "oats": Food(
                id: "oats",
                name: "Овсянка",
                macrosPer100g: Macros(calories: 370, protein: 13, fat: 7, carbs: 60),
                nutrientsPer100g: ["iron": 4.0],
                tags: ["grain"],
                groups: ["grain"],
                allergens: []
            ),
            "banana": Food(
                id: "banana",
                name: "Банан",
                macrosPer100g: Macros(calories: 89, protein: 1.1, fat: 0.3, carbs: 23),
                nutrientsPer100g: ["vitamin_c": 8.7],
                tags: ["fruit"],
                groups: ["fruit"],
                allergens: []
            )
        ]

        let ingredients = [
            RecipeIngredient(foodId: "oats", grams: 50),
            RecipeIngredient(foodId: "banana", grams: 100)
        ]

        let summary = NutritionCalculator.summarize(
            ingredients: ingredients,
            foodsById: foodsById
        )

        XCTAssertEqual(summary.macros.calories, 274.0, accuracy: 0.01)
        XCTAssertEqual(summary.macros.protein, 7.6, accuracy: 0.01)
        XCTAssertEqual(summary.macros.fat, 3.8, accuracy: 0.01)
        XCTAssertEqual(summary.macros.carbs, 53.0, accuracy: 0.01)

        let iron = try XCTUnwrap(summary.nutrients["iron"])
        let vitaminC = try XCTUnwrap(summary.nutrients["vitamin_c"])

        XCTAssertEqual(iron, 2.0, accuracy: 0.01)
        XCTAssertEqual(vitaminC, 8.7, accuracy: 0.01)
    }

    func testSummarizeSkipsUnknownFoods() throws {
        let foodsById: [String: Food] = [
            "apple": Food(
                id: "apple",
                name: "Яблоко",
                macrosPer100g: Macros(calories: 52, protein: 0.3, fat: 0.2, carbs: 14),
                nutrientsPer100g: ["vitamin_c": 4.6],
                tags: ["fruit"],
                groups: ["fruit"],
                allergens: []
            )
        ]

        let ingredients = [
            RecipeIngredient(foodId: "apple", grams: 100),
            RecipeIngredient(foodId: "missing_food", grams: 500)
        ]

        let summary = NutritionCalculator.summarize(
            ingredients: ingredients,
            foodsById: foodsById
        )

        XCTAssertEqual(summary.macros.calories, 52, accuracy: 0.01)
        XCTAssertEqual(summary.macros.protein, 0.3, accuracy: 0.01)
        XCTAssertEqual(summary.macros.fat, 0.2, accuracy: 0.01)
        XCTAssertEqual(summary.macros.carbs, 14, accuracy: 0.01)

        let vitaminC = try XCTUnwrap(summary.nutrients["vitamin_c"])
        XCTAssertEqual(vitaminC, 4.6, accuracy: 0.01)
    }

    func testSummarizeReturnsZeroForEmptyIngredients() {
        let summary = NutritionCalculator.summarize(
            ingredients: [],
            foodsById: [:]
        )

        XCTAssertEqual(summary, .zero)
    }
}
