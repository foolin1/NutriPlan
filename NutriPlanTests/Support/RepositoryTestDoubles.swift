import Foundation
@testable import NutriPlan

final class TestFoodRepository: FoodRepository {
    private let foods: [Food]
    private let foodsById: [String: Food]

    init(foods: [Food]) {
        self.foods = foods
        self.foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })
    }

    func getAllFoods() -> [Food] {
        foods
    }

    func getFoodsById() -> [String: Food] {
        foodsById
    }

    func getFood(by id: String) -> Food? {
        foodsById[id]
    }
}

final class TestRecipeRepository: RecipeRepository {
    private let recipes: [Recipe]

    init(recipes: [Recipe]) {
        self.recipes = recipes
    }

    func getAllRecipes() -> [Recipe] {
        recipes
    }
}
