import Foundation

final class InMemoryFoodRepository: FoodRepository {
    private let foods: [Food]

    init(bundle: Bundle = .main) {
        if let loaded: [Food] = BundleJSONLoader.loadArray(Food.self, named: "foods", bundle: bundle),
           !loaded.isEmpty {
            self.foods = loaded
        } else {
            self.foods = Self.fallbackFoods
        }
    }

    func getAllFoods() -> [Food] {
        foods
    }

    func getFoodsById() -> [String: Food] {
        Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })
    }

    func getFood(by id: String) -> Food? {
        foods.first { $0.id == id }
    }

    private static let fallbackFoods: [Food] = [
        Food(
            id: "chicken_breast",
            name: "Chicken breast",
            macrosPer100g: Macros(calories: 165, protein: 31, fat: 3.6, carbs: 0),
            nutrientsPer100g: ["iron": 1.0],
            tags: ["meat"],
            groups: ["poultry"]
        ),
        Food(
            id: "rice",
            name: "Rice (cooked)",
            macrosPer100g: Macros(calories: 130, protein: 2.7, fat: 0.3, carbs: 28),
            nutrientsPer100g: ["iron": 0.2],
            tags: ["grain", "vegan"],
            groups: ["grain"]
        ),
        Food(
            id: "banana",
            name: "Banana",
            macrosPer100g: Macros(calories: 89, protein: 1.1, fat: 0.3, carbs: 22.8),
            nutrientsPer100g: ["vitamin_c": 8.7],
            tags: ["fruit", "vegan"],
            groups: ["fruit"]
        ),
        Food(
            id: "greek_yogurt",
            name: "Greek yogurt",
            macrosPer100g: Macros(calories: 73, protein: 10, fat: 2, carbs: 3.9),
            nutrientsPer100g: ["iron": 0.1],
            tags: ["dairy"],
            groups: ["dairy"],
            allergens: ["lactose"]
        )
    ]
}
