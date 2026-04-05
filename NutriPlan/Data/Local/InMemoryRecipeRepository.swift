import Foundation

final class InMemoryRecipeRepository: RecipeRepository {

    private let recipes: [Recipe] = [
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
            id: "yogurt_banana_bowl",
            name: "Yogurt + Banana Bowl",
            ingredients: [
                RecipeIngredient(foodId: "greek_yogurt", grams: 200),
                RecipeIngredient(foodId: "banana", grams: 120),
                RecipeIngredient(foodId: "blueberries", grams: 60)
            ],
            cookTimeMinutes: 5,
            tags: ["breakfast", "bowl"],
            isModified: false
        ),
        Recipe(
            id: "turkey_quinoa_bowl",
            name: "Turkey + Quinoa Bowl",
            ingredients: [
                RecipeIngredient(foodId: "turkey_breast", grams: 180),
                RecipeIngredient(foodId: "quinoa", grams: 200),
                RecipeIngredient(foodId: "broccoli", grams: 80)
            ],
            cookTimeMinutes: 25,
            tags: ["lunch", "bowl", "high_protein"],
            isModified: false
        ),
        Recipe(
            id: "chicken_rice_bowl",
            name: "Chicken + Rice Bowl",
            ingredients: [
                RecipeIngredient(foodId: "chicken_breast", grams: 180),
                RecipeIngredient(foodId: "rice", grams: 200),
                RecipeIngredient(foodId: "spinach", grams: 40)
            ],
            cookTimeMinutes: 25,
            tags: ["lunch", "bowl", "high_protein"],
            isModified: false
        ),
        Recipe(
            id: "lentils_spinach_plate",
            name: "Lentils + Spinach Plate",
            ingredients: [
                RecipeIngredient(foodId: "lentils", grams: 220),
                RecipeIngredient(foodId: "spinach", grams: 120),
                RecipeIngredient(foodId: "avocado", grams: 60)
            ],
            cookTimeMinutes: 20,
            tags: ["dinner", "plate", "iron_rich"],
            isModified: false
        ),
        Recipe(
            id: "chicken_rice_plate",
            name: "Chicken + Rice Plate",
            ingredients: [
                RecipeIngredient(foodId: "chicken_breast", grams: 180),
                RecipeIngredient(foodId: "rice", grams: 200),
                RecipeIngredient(foodId: "spinach", grams: 60)
            ],
            cookTimeMinutes: 25,
            tags: ["dinner", "plate", "high_protein"],
            isModified: false
        ),
        Recipe(
            id: "yogurt_berries_snack",
            name: "Yogurt + Berries Snack",
            ingredients: [
                RecipeIngredient(foodId: "greek_yogurt", grams: 180),
                RecipeIngredient(foodId: "blueberries", grams: 80)
            ],
            cookTimeMinutes: 5,
            tags: ["snack", "bowl"],
            isModified: false
        ),
        Recipe(
            id: "pumpkin_apple_snack",
            name: "Pumpkin Seeds + Apple Snack",
            ingredients: [
                RecipeIngredient(foodId: "pumpkin_seeds", grams: 30),
                RecipeIngredient(foodId: "apple", grams: 120)
            ],
            cookTimeMinutes: 3,
            tags: ["snack", "plate", "iron_rich"],
            isModified: false
        )
    ]

    func getAllRecipes() -> [Recipe] {
        recipes
    }
}
