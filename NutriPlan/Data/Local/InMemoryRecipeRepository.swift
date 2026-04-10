import Foundation

final class InMemoryRecipeRepository: RecipeRepository {
    private let recipes: [Recipe]

    init(bundle: Bundle = .main) {
        if let loaded: [Recipe] = BundleJSONLoader.loadArray(Recipe.self, named: "recipes", bundle: bundle),
           !loaded.isEmpty {
            self.recipes = loaded
        } else {
            self.recipes = Self.fallbackRecipes
        }
    }

    func getAllRecipes() -> [Recipe] {
        recipes
    }

    private static let fallbackRecipes: [Recipe] = [
        Recipe(
            id: "oatmeal_bowl",
            name: "Oatmeal Bowl",
            ingredients: [
                RecipeIngredient(foodId: "oats", grams: 60),
                RecipeIngredient(foodId: "greek_yogurt", grams: 150),
                RecipeIngredient(foodId: "banana", grams: 100)
            ],
            cookTimeMinutes: 10,
            tags: ["breakfast", "bowl"],
            isModified: false
        ),
        Recipe(
            id: "chicken_rice_bowl",
            name: "Chicken + Rice Bowl",
            ingredients: [
                RecipeIngredient(foodId: "chicken_breast", grams: 180),
                RecipeIngredient(foodId: "rice", grams: 200)
            ],
            cookTimeMinutes: 25,
            tags: ["lunch", "bowl", "high_protein"],
            isModified: false
        )
    ]
}
