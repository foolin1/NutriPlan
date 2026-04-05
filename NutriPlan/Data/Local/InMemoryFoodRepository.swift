import Foundation

final class InMemoryFoodRepository: FoodRepository {

    private let foods: [Food] = [
        Food(
            id: "chicken_breast",
            name: "Chicken breast",
            macrosPer100g: Macros(calories: 165, protein: 31, fat: 3.6, carbs: 0),
            nutrientsPer100g: ["iron": 1.0],
            tags: ["meat"],
            allergens: []
        ),
        Food(
            id: "turkey_breast",
            name: "Turkey breast",
            macrosPer100g: Macros(calories: 135, protein: 29, fat: 1.6, carbs: 0),
            nutrientsPer100g: ["iron": 1.2],
            tags: ["meat"],
            allergens: []
        ),
        Food(
            id: "rice",
            name: "Rice (cooked)",
            macrosPer100g: Macros(calories: 130, protein: 2.7, fat: 0.3, carbs: 28),
            nutrientsPer100g: ["iron": 0.2],
            tags: ["grain", "vegan"],
            allergens: []
        ),
        Food(
            id: "quinoa",
            name: "Quinoa (cooked)",
            macrosPer100g: Macros(calories: 120, protein: 4.4, fat: 1.9, carbs: 21.3),
            nutrientsPer100g: ["iron": 1.5],
            tags: ["grain", "vegan"],
            allergens: []
        ),
        Food(
            id: "oats",
            name: "Oats",
            macrosPer100g: Macros(calories: 389, protein: 16.9, fat: 6.9, carbs: 66.3),
            nutrientsPer100g: ["iron": 4.7],
            tags: ["grain", "vegan"],
            allergens: ["gluten"]
        ),
        Food(
            id: "greek_yogurt",
            name: "Greek yogurt",
            macrosPer100g: Macros(calories: 73, protein: 10, fat: 2, carbs: 3.9),
            nutrientsPer100g: ["iron": 0.1],
            tags: ["dairy"],
            allergens: ["lactose"]
        ),
        Food(
            id: "blueberries",
            name: "Blueberries",
            macrosPer100g: Macros(calories: 57, protein: 0.7, fat: 0.3, carbs: 14.5),
            nutrientsPer100g: ["vitamin_c": 9.7],
            tags: ["fruit", "vegan"],
            allergens: []
        ),
        Food(
            id: "banana",
            name: "Banana",
            macrosPer100g: Macros(calories: 89, protein: 1.1, fat: 0.3, carbs: 22.8),
            nutrientsPer100g: ["vitamin_c": 8.7],
            tags: ["fruit", "vegan"],
            allergens: []
        ),
        Food(
            id: "apple",
            name: "Apple",
            macrosPer100g: Macros(calories: 52, protein: 0.3, fat: 0.2, carbs: 14),
            nutrientsPer100g: ["iron": 0.1, "vitamin_c": 4.6],
            tags: ["fruit", "vegan"],
            allergens: []
        ),
        Food(
            id: "spinach",
            name: "Spinach",
            macrosPer100g: Macros(calories: 23, protein: 2.9, fat: 0.4, carbs: 3.6),
            nutrientsPer100g: ["iron": 2.7, "vitamin_c": 28.0],
            tags: ["vegetable", "vegan"],
            allergens: []
        ),
        Food(
            id: "broccoli",
            name: "Broccoli",
            macrosPer100g: Macros(calories: 34, protein: 2.8, fat: 0.4, carbs: 6.6),
            nutrientsPer100g: ["iron": 0.7, "vitamin_c": 89.0],
            tags: ["vegetable", "vegan"],
            allergens: []
        ),
        Food(
            id: "avocado",
            name: "Avocado",
            macrosPer100g: Macros(calories: 160, protein: 2, fat: 14.7, carbs: 8.5),
            nutrientsPer100g: ["vitamin_c": 10.0],
            tags: ["fruit", "vegan"],
            allergens: []
        ),
        Food(
            id: "lentils",
            name: "Lentils (cooked)",
            macrosPer100g: Macros(calories: 116, protein: 9, fat: 0.4, carbs: 20.1),
            nutrientsPer100g: ["iron": 3.3],
            tags: ["legume", "vegan"],
            allergens: []
        ),
        Food(
            id: "pumpkin_seeds",
            name: "Pumpkin seeds",
            macrosPer100g: Macros(calories: 559, protein: 30.2, fat: 49.0, carbs: 10.7),
            nutrientsPer100g: ["iron": 8.8],
            tags: ["seed", "vegan"],
            allergens: []
        )
    ]

    func getAllFoods() -> [Food] {
        foods
    }

    func getFoodsById() -> [String: Food] {
        Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })
    }

    func getFood(by id: String) -> Food? {
        foods.first { $0.id == id }
    }
}
