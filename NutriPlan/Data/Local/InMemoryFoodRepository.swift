import Foundation

final class InMemoryFoodRepository: FoodRepository {
    private let foods: [Food]

    init(bundle: Bundle = .main) {
        if let loaded: [Food] = BundleJSONLoader.loadArray(
            Food.self,
            named: "foods",
            bundle: bundle
        ), !loaded.isEmpty {
            self.foods = loaded
        } else {
            self.foods = Self.fallbackFoods
            print("foods.json не найден или пуст. Используется резервный каталог продуктов.")
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
        // MARK: - Белковые продукты: мясо, птица, рыба, альтернативы

        Food(
            id: "chicken_breast",
            name: "Куриная грудка",
            macrosPer100g: Macros(calories: 165, protein: 31.0, fat: 3.6, carbs: 0.0),
            nutrientsPer100g: [
                "iron": 1.0,
                "calcium": 12.0,
                "magnesium": 29.0
            ],
            tags: ["meat", "high_protein"],
            groups: ["poultry"],
            allergens: []
        ),
        Food(
            id: "turkey_breast",
            name: "Грудка индейки",
            macrosPer100g: Macros(calories: 135, protein: 29.0, fat: 1.6, carbs: 0.0),
            nutrientsPer100g: [
                "iron": 1.2,
                "calcium": 11.0,
                "magnesium": 28.0
            ],
            tags: ["meat", "high_protein"],
            groups: ["poultry"],
            allergens: []
        ),
        Food(
            id: "lean_beef",
            name: "Постная говядина",
            macrosPer100g: Macros(calories: 187, protein: 27.0, fat: 8.0, carbs: 0.0),
            nutrientsPer100g: [
                "iron": 2.6,
                "calcium": 18.0,
                "magnesium": 21.0
            ],
            tags: ["meat", "high_protein"],
            groups: ["red_meat"],
            allergens: []
        ),
        Food(
            id: "veal",
            name: "Телятина",
            macrosPer100g: Macros(calories: 172, protein: 30.0, fat: 5.0, carbs: 0.0),
            nutrientsPer100g: [
                "iron": 1.4,
                "calcium": 12.0,
                "magnesium": 24.0
            ],
            tags: ["meat", "high_protein"],
            groups: ["red_meat"],
            allergens: []
        ),
        Food(
            id: "salmon",
            name: "Лосось",
            macrosPer100g: Macros(calories: 208, protein: 20.0, fat: 13.0, carbs: 0.0),
            nutrientsPer100g: [
                "iron": 0.5,
                "calcium": 9.0,
                "magnesium": 29.0
            ],
            tags: ["seafood", "high_protein"],
            groups: ["seafood"],
            allergens: ["fish"]
        ),
        Food(
            id: "tuna",
            name: "Тунец",
            macrosPer100g: Macros(calories: 132, protein: 29.0, fat: 1.0, carbs: 0.0),
            nutrientsPer100g: [
                "iron": 1.0,
                "calcium": 10.0,
                "magnesium": 50.0
            ],
            tags: ["seafood", "high_protein"],
            groups: ["seafood"],
            allergens: ["fish"]
        ),
        Food(
            id: "cod",
            name: "Треска",
            macrosPer100g: Macros(calories: 82, protein: 18.0, fat: 0.7, carbs: 0.0),
            nutrientsPer100g: [
                "iron": 0.4,
                "calcium": 16.0,
                "magnesium": 32.0
            ],
            tags: ["seafood", "high_protein"],
            groups: ["seafood"],
            allergens: ["fish"]
        ),
        Food(
            id: "shrimp",
            name: "Креветки",
            macrosPer100g: Macros(calories: 99, protein: 24.0, fat: 0.3, carbs: 0.2),
            nutrientsPer100g: [
                "iron": 0.5,
                "calcium": 70.0,
                "magnesium": 39.0
            ],
            tags: ["seafood", "high_protein"],
            groups: ["seafood"],
            allergens: ["shellfish"]
        ),
        Food(
            id: "eggs",
            name: "Яйца",
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
            id: "tofu",
            name: "Тофу",
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

        // MARK: - Гарниры, крупы, бобовые

        Food(
            id: "rice",
            name: "Рис",
            macrosPer100g: Macros(calories: 130, protein: 2.7, fat: 0.3, carbs: 28.0),
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
            name: "Киноа",
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
            id: "buckwheat",
            name: "Гречка",
            macrosPer100g: Macros(calories: 110, protein: 4.2, fat: 1.1, carbs: 21.3),
            nutrientsPer100g: [
                "iron": 0.8,
                "calcium": 7.0,
                "magnesium": 51.0
            ],
            tags: ["grain", "vegan"],
            groups: ["grain"],
            allergens: []
        ),
        Food(
            id: "bulgur",
            name: "Булгур",
            macrosPer100g: Macros(calories: 83, protein: 3.1, fat: 0.2, carbs: 18.6),
            nutrientsPer100g: [
                "iron": 0.9,
                "calcium": 10.0,
                "magnesium": 32.0
            ],
            tags: ["grain", "vegan"],
            groups: ["grain"],
            allergens: ["gluten"]
        ),
        Food(
            id: "wholegrain_pasta",
            name: "Цельнозерновая паста",
            macrosPer100g: Macros(calories: 124, protein: 5.0, fat: 0.9, carbs: 26.0),
            nutrientsPer100g: [
                "iron": 1.4,
                "calcium": 18.0,
                "magnesium": 43.0
            ],
            tags: ["grain"],
            groups: ["grain"],
            allergens: ["gluten"]
        ),
        Food(
            id: "potato",
            name: "Картофель",
            macrosPer100g: Macros(calories: 77, protein: 2.0, fat: 0.1, carbs: 17.0),
            nutrientsPer100g: [
                "iron": 0.8,
                "calcium": 12.0,
                "magnesium": 23.0,
                "vitamin_c": 19.7
            ],
            tags: ["grain", "vegan"],
            groups: ["grain"],
            allergens: []
        ),
        Food(
            id: "sweet_potato",
            name: "Батат",
            macrosPer100g: Macros(calories: 86, protein: 1.6, fat: 0.1, carbs: 20.1),
            nutrientsPer100g: [
                "iron": 0.6,
                "calcium": 30.0,
                "magnesium": 25.0,
                "vitamin_c": 2.4
            ],
            tags: ["grain", "vegan"],
            groups: ["grain"],
            allergens: []
        ),
        Food(
            id: "oats",
            name: "Овсяные хлопья",
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
            name: "Цельнозерновой хлеб",
            macrosPer100g: Macros(calories: 247, protein: 13.0, fat: 4.2, carbs: 41.0),
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
            id: "lentils",
            name: "Чечевица",
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
            name: "Нут",
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
            id: "red_beans",
            name: "Красная фасоль",
            macrosPer100g: Macros(calories: 127, protein: 8.7, fat: 0.5, carbs: 22.8),
            nutrientsPer100g: [
                "iron": 2.9,
                "calcium": 28.0,
                "magnesium": 45.0
            ],
            tags: ["legume", "vegan"],
            groups: ["legumes"],
            allergens: []
        ),

        // MARK: - Молочные продукты

        Food(
            id: "greek_yogurt",
            name: "Греческий йогурт",
            macrosPer100g: Macros(calories: 73, protein: 10.0, fat: 2.0, carbs: 3.9),
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
            name: "Творог",
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
            name: "Молоко",
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
            id: "kefir",
            name: "Кефир",
            macrosPer100g: Macros(calories: 51, protein: 3.4, fat: 2.0, carbs: 4.7),
            nutrientsPer100g: [
                "iron": 0.1,
                "calcium": 120.0,
                "magnesium": 12.0
            ],
            tags: ["dairy"],
            groups: ["dairy"],
            allergens: ["lactose"]
        ),
        Food(
            id: "hard_cheese",
            name: "Твёрдый сыр",
            macrosPer100g: Macros(calories: 350, protein: 25.0, fat: 27.0, carbs: 1.5),
            nutrientsPer100g: [
                "iron": 0.7,
                "calcium": 700.0,
                "magnesium": 28.0
            ],
            tags: ["dairy"],
            groups: ["dairy"],
            allergens: ["lactose"]
        ),

        // MARK: - Фрукты и ягоды

        Food(
            id: "blueberries",
            name: "Черника",
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
            id: "strawberries",
            name: "Клубника",
            macrosPer100g: Macros(calories: 32, protein: 0.7, fat: 0.3, carbs: 7.7),
            nutrientsPer100g: [
                "calcium": 16.0,
                "magnesium": 13.0,
                "vitamin_c": 58.8
            ],
            tags: ["fruit", "vegan"],
            groups: ["berries"],
            allergens: []
        ),
        Food(
            id: "raspberries",
            name: "Малина",
            macrosPer100g: Macros(calories: 52, protein: 1.2, fat: 0.7, carbs: 11.9),
            nutrientsPer100g: [
                "iron": 0.7,
                "calcium": 25.0,
                "magnesium": 22.0,
                "vitamin_c": 26.2
            ],
            tags: ["fruit", "vegan"],
            groups: ["berries"],
            allergens: []
        ),
        Food(
            id: "banana",
            name: "Банан",
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
            name: "Яблоко",
            macrosPer100g: Macros(calories: 52, protein: 0.3, fat: 0.2, carbs: 14.0),
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
            id: "pear",
            name: "Груша",
            macrosPer100g: Macros(calories: 57, protein: 0.4, fat: 0.1, carbs: 15.2),
            nutrientsPer100g: [
                "iron": 0.2,
                "calcium": 9.0,
                "magnesium": 7.0,
                "vitamin_c": 4.3
            ],
            tags: ["fruit", "vegan"],
            groups: ["fruit"],
            allergens: []
        ),
        Food(
            id: "orange",
            name: "Апельсин",
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
            name: "Киви",
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
            id: "grapefruit",
            name: "Грейпфрут",
            macrosPer100g: Macros(calories: 42, protein: 0.8, fat: 0.1, carbs: 10.7),
            nutrientsPer100g: [
                "calcium": 22.0,
                "magnesium": 9.0,
                "vitamin_c": 31.2
            ],
            tags: ["fruit", "vegan"],
            groups: ["citrus"],
            allergens: []
        ),
        Food(
            id: "avocado",
            name: "Авокадо",
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

        // MARK: - Овощи

        Food(
            id: "spinach",
            name: "Шпинат",
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
            name: "Брокколи",
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
            name: "Красный сладкий перец",
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
            id: "cucumber",
            name: "Огурец",
            macrosPer100g: Macros(calories: 15, protein: 0.7, fat: 0.1, carbs: 3.6),
            nutrientsPer100g: [
                "calcium": 16.0,
                "magnesium": 13.0,
                "vitamin_c": 2.8
            ],
            tags: ["vegetable", "vegan"],
            groups: ["vegetable"],
            allergens: []
        ),
        Food(
            id: "tomato",
            name: "Помидор",
            macrosPer100g: Macros(calories: 18, protein: 0.9, fat: 0.2, carbs: 3.9),
            nutrientsPer100g: [
                "calcium": 10.0,
                "magnesium": 11.0,
                "vitamin_c": 13.7
            ],
            tags: ["vegetable", "vegan"],
            groups: ["vegetable"],
            allergens: []
        ),
        Food(
            id: "zucchini",
            name: "Кабачок",
            macrosPer100g: Macros(calories: 17, protein: 1.2, fat: 0.3, carbs: 3.1),
            nutrientsPer100g: [
                "calcium": 16.0,
                "magnesium": 18.0,
                "vitamin_c": 17.9
            ],
            tags: ["vegetable", "vegan"],
            groups: ["vegetable"],
            allergens: []
        ),
        Food(
            id: "beetroot",
            name: "Свёкла",
            macrosPer100g: Macros(calories: 43, protein: 1.6, fat: 0.2, carbs: 9.6),
            nutrientsPer100g: [
                "iron": 0.8,
                "calcium": 16.0,
                "magnesium": 23.0,
                "vitamin_c": 4.9
            ],
            tags: ["vegetable", "vegan"],
            groups: ["vegetable"],
            allergens: []
        ),
        Food(
            id: "carrot",
            name: "Морковь",
            macrosPer100g: Macros(calories: 41, protein: 0.9, fat: 0.2, carbs: 9.6),
            nutrientsPer100g: [
                "iron": 0.3,
                "calcium": 33.0,
                "magnesium": 12.0,
                "vitamin_c": 5.9
            ],
            tags: ["vegetable", "vegan"],
            groups: ["vegetable"],
            allergens: []
        ),
        Food(
            id: "mushrooms",
            name: "Шампиньоны",
            macrosPer100g: Macros(calories: 22, protein: 3.1, fat: 0.3, carbs: 3.3),
            nutrientsPer100g: [
                "iron": 0.5,
                "calcium": 3.0,
                "magnesium": 9.0,
                "vitamin_c": 2.1
            ],
            tags: ["vegetable", "vegan"],
            groups: ["vegetable"],
            allergens: []
        ),

        // MARK: - Орехи, семена и прочее

        Food(
            id: "pumpkin_seeds",
            name: "Тыквенные семечки",
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
            name: "Миндаль",
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
            id: "walnuts",
            name: "Грецкий орех",
            macrosPer100g: Macros(calories: 654, protein: 15.2, fat: 65.2, carbs: 13.7),
            nutrientsPer100g: [
                "iron": 2.9,
                "calcium": 98.0,
                "magnesium": 158.0
            ],
            tags: ["nut", "vegan"],
            groups: ["nuts"],
            allergens: ["nuts"]
        ),
        Food(
            id: "dark_chocolate",
            name: "Тёмный шоколад",
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
}
