import Foundation

final class InMemoryFoodRepository: FoodRepository {
    private let foods: [Food] = [
        Food(
            id: "chicken_breast",
            name: "Chicken breast",
            macrosPer100g: Macros(calories: 165, protein: 31, fat: 3.6, carbs: 0),
            nutrientsPer100g: [
                "iron": 1.0,
                "calcium": 12.0,
                "magnesium": 29.0
            ],
            tags: ["meat"],
            groups: ["poultry"],
            allergens: []
        ),
        Food(
            id: "turkey_breast",
            name: "Turkey breast",
            macrosPer100g: Macros(calories: 135, protein: 29, fat: 1.6, carbs: 0),
            nutrientsPer100g: [
                "iron": 1.2,
                "calcium": 11.0,
                "magnesium": 28.0
            ],
            tags: ["meat"],
            groups: ["poultry"],
            allergens: []
        ),
        Food(
            id: "salmon",
            name: "Salmon",
            macrosPer100g: Macros(calories: 208, protein: 20, fat: 13, carbs: 0),
            nutrientsPer100g: [
                "iron": 0.5,
                "calcium": 9.0,
                "magnesium": 29.0
            ],
            tags: ["seafood"],
            groups: ["seafood"],
            allergens: ["fish"]
        ),
        Food(
            id: "tuna",
            name: "Tuna",
            macrosPer100g: Macros(calories: 132, protein: 29, fat: 1.0, carbs: 0),
            nutrientsPer100g: [
                "iron": 1.0,
                "calcium": 10.0,
                "magnesium": 50.0
            ],
            tags: ["seafood"],
            groups: ["seafood"],
            allergens: ["fish"]
        ),
        Food(
            id: "eggs",
            name: "Eggs",
            macrosPer100g: Macros(calories: 143, protein: 12.6, fat: 9.5, carbs: 0.7),
            nutrientsPer100g: [
                "iron": 1.8,
                "calcium": 56.0,
                "magnesium": 12.0
            ],
            tags: ["egg"],
            groups: ["eggs"],
            allergens: ["egg"]
        ),
        Food(
            id: "rice",
            name: "Rice (cooked)",
            macrosPer100g: Macros(calories: 130, protein: 2.7, fat: 0.3, carbs: 28),
            nutrientsPer100g: [
                "iron": 0.2,
                "calcium": 10.0,
                "magnesium": 12.0
            ],
            tags: ["grain", "vegan"],
            groups: ["grain"],
            allergens: []
        ),
        Food(
            id: "quinoa",
            name: "Quinoa (cooked)",
            macrosPer100g: Macros(calories: 120, protein: 4.4, fat: 1.9, carbs: 21.3),
            nutrientsPer100g: [
                "iron": 1.5,
                "calcium": 17.0,
                "magnesium": 64.0
            ],
            tags: ["grain", "vegan"],
            groups: ["grain"],
            allergens: []
        ),
        Food(
            id: "oats",
            name: "Oats",
            macrosPer100g: Macros(calories: 389, protein: 16.9, fat: 6.9, carbs: 66.3),
            nutrientsPer100g: [
                "iron": 4.7,
                "calcium": 54.0,
                "magnesium": 177.0
            ],
            tags: ["grain", "vegan"],
            groups: ["grain"],
            allergens: ["gluten"]
        ),
        Food(
            id: "wholegrain_bread",
            name: "Wholegrain bread",
            macrosPer100g: Macros(calories: 247, protein: 13, fat: 4.2, carbs: 41),
            nutrientsPer100g: [
                "iron": 3.0,
                "calcium": 107.0,
                "magnesium": 82.0
            ],
            tags: ["grain"],
            groups: ["grain"],
            allergens: ["gluten"]
        ),
        Food(
            id: "greek_yogurt",
            name: "Greek yogurt",
            macrosPer100g: Macros(calories: 73, protein: 10, fat: 2, carbs: 3.9),
            nutrientsPer100g: [
                "iron": 0.1,
                "calcium": 110.0,
                "magnesium": 11.0
            ],
            tags: ["dairy"],
            groups: ["dairy"],
            allergens: ["lactose"]
        ),
        Food(
            id: "cottage_cheese",
            name: "Cottage cheese",
            macrosPer100g: Macros(calories: 98, protein: 11.1, fat: 4.3, carbs: 3.4),
            nutrientsPer100g: [
                "iron": 0.1,
                "calcium": 83.0,
                "magnesium": 8.0
            ],
            tags: ["dairy"],
            groups: ["dairy"],
            allergens: ["lactose"]
        ),
        Food(
            id: "milk",
            name: "Milk",
            macrosPer100g: Macros(calories: 52, protein: 3.4, fat: 2.5, carbs: 4.8),
            nutrientsPer100g: [
                "iron": 0.0,
                "calcium": 120.0,
                "magnesium": 10.0
            ],
            tags: ["dairy"],
            groups: ["dairy"],
            allergens: ["lactose"]
        ),
        Food(
            id: "hard_cheese",
            name: "Hard cheese",
            macrosPer100g: Macros(calories: 350, protein: 25, fat: 27, carbs: 1.5),
            nutrientsPer100g: [
                "iron": 0.7,
                "calcium": 700.0,
                "magnesium": 28.0
            ],
            tags: ["dairy"],
            groups: ["dairy"],
            allergens: ["lactose"]
        ),
        Food(
            id: "tofu",
            name: "Tofu",
            macrosPer100g: Macros(calories: 144, protein: 17.3, fat: 8.7, carbs: 2.8),
            nutrientsPer100g: [
                "iron": 5.4,
                "calcium": 350.0,
                "magnesium": 30.0
            ],
            tags: ["protein_alt", "vegan"],
            groups: ["protein_alt"],
            allergens: ["soy"]
        ),
        Food(
            id: "blueberries",
            name: "Blueberries",
            macrosPer100g: Macros(calories: 57, protein: 0.7, fat: 0.3, carbs: 14.5),
            nutrientsPer100g: [
                "calcium": 6.0,
                "magnesium": 6.0,
                "vitamin_c": 9.7
            ],
            tags: ["fruit", "vegan"],
            groups: ["berries"],
            allergens: []
        ),
        Food(
            id: "banana",
            name: "Banana",
            macrosPer100g: Macros(calories: 89, protein: 1.1, fat: 0.3, carbs: 22.8),
            nutrientsPer100g: [
                "calcium": 5.0,
                "magnesium": 27.0,
                "vitamin_c": 8.7
            ],
            tags: ["fruit", "vegan"],
            groups: ["fruit"],
            allergens: []
        ),
        Food(
            id: "apple",
            name: "Apple",
            macrosPer100g: Macros(calories: 52, protein: 0.3, fat: 0.2, carbs: 14),
            nutrientsPer100g: [
                "iron": 0.1,
                "calcium": 6.0,
                "magnesium": 5.0,
                "vitamin_c": 4.6
            ],
            tags: ["fruit", "vegan"],
            groups: ["fruit"],
            allergens: []
        ),
        Food(
            id: "orange",
            name: "Orange",
            macrosPer100g: Macros(calories: 47, protein: 0.9, fat: 0.1, carbs: 11.8),
            nutrientsPer100g: [
                "calcium": 40.0,
                "magnesium": 10.0,
                "vitamin_c": 53.2
            ],
            tags: ["fruit", "vegan"],
            groups: ["citrus"],
            allergens: []
        ),
        Food(
            id: "kiwi",
            name: "Kiwi",
            macrosPer100g: Macros(calories: 61, protein: 1.1, fat: 0.5, carbs: 14.7),
            nutrientsPer100g: [
                "calcium": 34.0,
                "magnesium": 17.0,
                "vitamin_c": 92.7
            ],
            tags: ["fruit", "vegan"],
            groups: ["fruit"],
            allergens: []
        ),
        Food(
            id: "spinach",
            name: "Spinach",
            macrosPer100g: Macros(calories: 23, protein: 2.9, fat: 0.4, carbs: 3.6),
            nutrientsPer100g: [
                "iron": 2.7,
                "calcium": 99.0,
                "magnesium": 79.0,
                "vitamin_c": 28.0
            ],
            tags: ["vegetable", "vegan"],
            groups: ["vegetable"],
            allergens: []
        ),
        Food(
            id: "broccoli",
            name: "Broccoli",
            macrosPer100g: Macros(calories: 34, protein: 2.8, fat: 0.4, carbs: 6.6),
            nutrientsPer100g: [
                "iron": 0.7,
                "calcium": 47.0,
                "magnesium": 21.0,
                "vitamin_c": 89.0
            ],
            tags: ["vegetable", "vegan"],
            groups: ["vegetable"],
            allergens: []
        ),
        Food(
            id: "bell_pepper_red",
            name: "Red bell pepper",
            macrosPer100g: Macros(calories: 31, protein: 1.0, fat: 0.3, carbs: 6.0),
            nutrientsPer100g: [
                "calcium": 7.0,
                "magnesium": 12.0,
                "vitamin_c": 127.7
            ],
            tags: ["vegetable", "vegan"],
            groups: ["vegetable"],
            allergens: []
        ),
        Food(
            id: "avocado",
            name: "Avocado",
            macrosPer100g: Macros(calories: 160, protein: 2.0, fat: 14.7, carbs: 8.5),
            nutrientsPer100g: [
                "calcium": 12.0,
                "magnesium": 29.0,
                "vitamin_c": 10.0
            ],
            tags: ["fruit", "vegan"],
            groups: ["fruit"],
            allergens: []
        ),
        Food(
            id: "lentils",
            name: "Lentils (cooked)",
            macrosPer100g: Macros(calories: 116, protein: 9.0, fat: 0.4, carbs: 20.1),
            nutrientsPer100g: [
                "iron": 3.3,
                "calcium": 19.0,
                "magnesium": 36.0
            ],
            tags: ["legume", "vegan"],
            groups: ["legumes"],
            allergens: []
        ),
        Food(
            id: "chickpeas",
            name: "Chickpeas (cooked)",
            macrosPer100g: Macros(calories: 164, protein: 8.9, fat: 2.6, carbs: 27.4),
            nutrientsPer100g: [
                "iron": 2.9,
                "calcium": 49.0,
                "magnesium": 48.0
            ],
            tags: ["legume", "vegan"],
            groups: ["legumes"],
            allergens: []
        ),
        Food(
            id: "pumpkin_seeds",
            name: "Pumpkin seeds",
            macrosPer100g: Macros(calories: 559, protein: 30.2, fat: 49.0, carbs: 10.7),
            nutrientsPer100g: [
                "iron": 8.8,
                "calcium": 46.0,
                "magnesium": 592.0
            ],
            tags: ["seed", "vegan"],
            groups: ["nuts"],
            allergens: []
        ),
        Food(
            id: "almonds",
            name: "Almonds",
            macrosPer100g: Macros(calories: 579, protein: 21.2, fat: 49.9, carbs: 21.6),
            nutrientsPer100g: [
                "iron": 3.7,
                "calcium": 269.0,
                "magnesium": 270.0
            ],
            tags: ["nut", "vegan"],
            groups: ["nuts"],
            allergens: ["nuts"]
        ),
        Food(
            id: "dark_chocolate",
            name: "Dark chocolate",
            macrosPer100g: Macros(calories: 546, protein: 4.9, fat: 31.0, carbs: 61.0),
            nutrientsPer100g: [
                "iron": 11.9,
                "calcium": 73.0,
                "magnesium": 228.0
            ],
            tags: ["snack"],
            groups: ["other"],
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
