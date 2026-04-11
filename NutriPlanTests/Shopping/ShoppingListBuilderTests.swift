import Foundation
import Testing
@testable import NutriPlan

struct ShoppingListBuilderTests {
    @Test("Список покупок агрегирует одинаковые продукты из нескольких рецептов")
    func shoppingListAggregatesWeights() throws {
        let recipe1 = Recipe(
            id: "r1",
            name: "Рецепт 1",
            ingredients: [
                RecipeIngredient(foodId: "rice", grams: 100),
                RecipeIngredient(foodId: "chicken_breast", grams: 150)
            ],
            cookTimeMinutes: nil,
            tags: ["lunch"],
            isModified: false
        )

        let recipe2 = Recipe(
            id: "r2",
            name: "Рецепт 2",
            ingredients: [
                RecipeIngredient(foodId: "rice", grams: 150),
                RecipeIngredient(foodId: "broccoli", grams: 80)
            ],
            cookTimeMinutes: nil,
            tags: ["dinner"],
            isModified: false
        )

        let items = ShoppingListBuilder.build(
            recipes: [recipe1, recipe2],
            foodsById: TestDataFactory.foodsById
        )

        let riceItem = try #require(items.first(where: { $0.id == "rice" }))
        let chickenItem = try #require(items.first(where: { $0.id == "chicken_breast" }))
        let broccoliItem = try #require(items.first(where: { $0.id == "broccoli" }))

        #expect(riceItem.grams == 250)
        #expect(riceItem.categoryKey == "category.grain")

        #expect(chickenItem.grams == 150)
        #expect(chickenItem.categoryKey == "category.meat")

        #expect(broccoliItem.grams == 80)
        #expect(broccoliItem.categoryKey == "category.vegetable")
    }
}
