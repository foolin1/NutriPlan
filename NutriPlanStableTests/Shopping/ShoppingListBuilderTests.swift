import XCTest
@testable import NutriPlan

final class ShoppingListBuilderTests: XCTestCase {

    func testBuildMergesSameIngredientAcrossRecipes() {
        let foodsById: [String: Food] = [
            "rice": Food(
                id: "rice",
                name: "Рис",
                macrosPer100g: Macros(calories: 130, protein: 2.7, fat: 0.3, carbs: 28),
                nutrientsPer100g: [:],
                tags: ["grain"],
                groups: ["grain"],
                allergens: []
            ),
            "chicken_breast": Food(
                id: "chicken_breast",
                name: "Куриная грудка",
                macrosPer100g: Macros(calories: 165, protein: 31, fat: 3.6, carbs: 0),
                nutrientsPer100g: [:],
                tags: ["meat"],
                groups: ["poultry"],
                allergens: []
            )
        ]

        let recipe1 = Recipe(
            id: "r1",
            name: "Курица с рисом",
            ingredients: [
                RecipeIngredient(foodId: "rice", grams: 100),
                RecipeIngredient(foodId: "chicken_breast", grams: 150)
            ],
            cookTimeMinutes: 20,
            tags: [],
            isModified: false
        )

        let recipe2 = Recipe(
            id: "r2",
            name: "Рис с курицей",
            ingredients: [
                RecipeIngredient(foodId: "rice", grams: 80)
            ],
            cookTimeMinutes: 15,
            tags: [],
            isModified: false
        )

        let items = ShoppingListBuilder.build(
            recipes: [recipe1, recipe2],
            foodsById: foodsById
        )

        let riceItem = items.first(where: { $0.id == "rice" })
        let chickenItem = items.first(where: { $0.id == "chicken_breast" })

        XCTAssertEqual(riceItem?.grams, 180)
        XCTAssertEqual(chickenItem?.grams, 150)
    }

    func testBuildSkipsUnknownFoods() {
        let foodsById: [String: Food] = [
            "apple": Food(
                id: "apple",
                name: "Яблоко",
                macrosPer100g: Macros(calories: 52, protein: 0.3, fat: 0.2, carbs: 14),
                nutrientsPer100g: [:],
                tags: ["fruit"],
                groups: ["fruit"],
                allergens: []
            )
        ]

        let recipe = Recipe(
            id: "r1",
            name: "Перекус",
            ingredients: [
                RecipeIngredient(foodId: "apple", grams: 120),
                RecipeIngredient(foodId: "unknown_food", grams: 50)
            ],
            cookTimeMinutes: nil,
            tags: [],
            isModified: false
        )

        let items = ShoppingListBuilder.build(
            recipes: [recipe],
            foodsById: foodsById
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "apple")
    }

    func testBuildAssignsCategoryKeysByFoodTags() {
        let foodsById: [String: Food] = [
            "turkey": Food(
                id: "turkey",
                name: "Индейка",
                macrosPer100g: Macros(calories: 135, protein: 29, fat: 1.6, carbs: 0),
                nutrientsPer100g: [:],
                tags: ["meat"],
                groups: ["poultry"],
                allergens: []
            ),
            "buckwheat": Food(
                id: "buckwheat",
                name: "Гречка",
                macrosPer100g: Macros(calories: 110, protein: 3.6, fat: 1.1, carbs: 21),
                nutrientsPer100g: [:],
                tags: ["grain"],
                groups: ["grain"],
                allergens: []
            ),
            "broccoli": Food(
                id: "broccoli",
                name: "Брокколи",
                macrosPer100g: Macros(calories: 35, protein: 2.8, fat: 0.4, carbs: 7),
                nutrientsPer100g: [:],
                tags: ["vegetable"],
                groups: ["vegetable"],
                allergens: []
            )
        ]

        let recipe = Recipe(
            id: "r1",
            name: "Обед",
            ingredients: [
                RecipeIngredient(foodId: "turkey", grams: 150),
                RecipeIngredient(foodId: "buckwheat", grams: 120),
                RecipeIngredient(foodId: "broccoli", grams: 100)
            ],
            cookTimeMinutes: 25,
            tags: [],
            isModified: false
        )

        let items = ShoppingListBuilder.build(
            recipes: [recipe],
            foodsById: foodsById
        )

        XCTAssertEqual(items.first(where: { $0.id == "turkey" })?.categoryKey, "category.meat")
        XCTAssertEqual(items.first(where: { $0.id == "buckwheat" })?.categoryKey, "category.grain")
        XCTAssertEqual(items.first(where: { $0.id == "broccoli" })?.categoryKey, "category.vegetable")
    }
}
