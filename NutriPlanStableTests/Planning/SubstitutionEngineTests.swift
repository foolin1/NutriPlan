import XCTest
@testable import NutriPlan

final class SubstitutionEngineTests: XCTestCase {

    func testSuggestExcludesFoodsWithForbiddenAllergens() {
        let chicken = makeFood(
            id: "chicken_breast",
            name: "Куриная грудка",
            macros: Macros(calories: 165, protein: 31, fat: 3.6, carbs: 0),
            tags: ["meat", "high_protein"],
            groups: ["poultry"]
        )

        let shrimp = makeFood(
            id: "shrimp",
            name: "Креветки",
            macros: Macros(calories: 99, protein: 24, fat: 0.3, carbs: 0.2),
            tags: ["seafood", "high_protein"],
            groups: ["seafood"],
            allergens: ["shellfish"]
        )

        let turkey = makeFood(
            id: "turkey_breast",
            name: "Филе индейки",
            macros: Macros(calories: 135, protein: 29, fat: 1.6, carbs: 0),
            tags: ["meat", "high_protein"],
            groups: ["poultry"]
        )

        let foods = [chicken, shrimp, turkey]
        let foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let suggestions = SubstitutionEngine.suggest(
            originalFoodId: "chicken_breast",
            grams: 150,
            foods: foods,
            foodsById: foodsById,
            excludedAllergens: ["shellfish"]
        )

        XCTAssertFalse(suggestions.contains(where: { $0.id == "shrimp" }))
        XCTAssertTrue(suggestions.contains(where: { $0.id == "turkey_breast" }))
    }

    func testSuggestExcludesFoodsFromExcludedGroups() {
        let milk = makeFood(
            id: "milk",
            name: "Молоко",
            macros: Macros(calories: 52, protein: 3.4, fat: 2.5, carbs: 4.8),
            tags: ["dairy"],
            groups: ["dairy"]
        )

        let kefir = makeFood(
            id: "kefir",
            name: "Кефир",
            macros: Macros(calories: 51, protein: 3.3, fat: 2.0, carbs: 4.0),
            tags: ["dairy"],
            groups: ["dairy"]
        )

        let yogurt = makeFood(
            id: "yogurt",
            name: "Йогурт",
            macros: Macros(calories: 59, protein: 3.5, fat: 3.3, carbs: 4.7),
            tags: ["dairy"],
            groups: ["dairy"]
        )

        let foods = [milk, kefir, yogurt]
        let foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let suggestions = SubstitutionEngine.suggest(
            originalFoodId: "milk",
            grams: 200,
            foods: foods,
            foodsById: foodsById,
            excludedAllergens: [],
            excludedGroups: ["dairy"]
        )

        XCTAssertTrue(suggestions.isEmpty)
    }

    func testSuggestExcludesProductsByNameSubstring() {
        let banana = makeFood(
            id: "banana",
            name: "Банан",
            macros: Macros(calories: 89, protein: 1.1, fat: 0.3, carbs: 23),
            tags: ["fruit"],
            groups: ["fruit"]
        )

        let pear = makeFood(
            id: "pear",
            name: "Груша",
            macros: Macros(calories: 57, protein: 0.4, fat: 0.1, carbs: 15),
            tags: ["fruit"],
            groups: ["fruit"]
        )

        let apple = makeFood(
            id: "apple",
            name: "Яблоко",
            macros: Macros(calories: 52, protein: 0.3, fat: 0.2, carbs: 14),
            tags: ["fruit"],
            groups: ["fruit"]
        )

        let foods = [banana, pear, apple]
        let foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let suggestions = SubstitutionEngine.suggest(
            originalFoodId: "banana",
            grams: 120,
            foods: foods,
            foodsById: foodsById,
            excludedAllergens: [],
            excludedProducts: ["яблок"]
        )

        XCTAssertFalse(suggestions.contains(where: { $0.id == "apple" }))
        XCTAssertTrue(suggestions.contains(where: { $0.id == "pear" }))
    }

    func testSuggestAppliesRequiredTags() {
        let rice = makeFood(
            id: "rice",
            name: "Рис",
            macros: Macros(calories: 130, protein: 2.7, fat: 0.3, carbs: 28),
            tags: ["grain"],
            groups: ["grain"]
        )

        let quinoa = makeFood(
            id: "quinoa",
            name: "Киноа",
            macros: Macros(calories: 120, protein: 4.4, fat: 1.9, carbs: 21.3),
            tags: ["grain", "gluten_free"],
            groups: ["grain"]
        )

        let couscous = makeFood(
            id: "couscous",
            name: "Кускус",
            macros: Macros(calories: 125, protein: 3.8, fat: 0.2, carbs: 25),
            tags: ["grain"],
            groups: ["grain"]
        )

        let foods = [rice, quinoa, couscous]
        let foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let suggestions = SubstitutionEngine.suggest(
            originalFoodId: "rice",
            grams: 100,
            foods: foods,
            foodsById: foodsById,
            excludedAllergens: [],
            requiredTags: ["gluten_free"]
        )

        XCTAssertEqual(suggestions.count, 1)
        XCTAssertEqual(suggestions.first?.id, "quinoa")
    }

    func testSuggestRanksCloserMacrosHigher() {
        let rice = makeFood(
            id: "rice",
            name: "Рис",
            macros: Macros(calories: 130, protein: 2.7, fat: 0.3, carbs: 28.0),
            tags: ["grain"],
            groups: ["grain"]
        )

        let couscous = makeFood(
            id: "couscous",
            name: "Кускус",
            macros: Macros(calories: 125, protein: 3.8, fat: 0.2, carbs: 25.0),
            tags: ["grain"],
            groups: ["grain"]
        )

        let lentils = makeFood(
            id: "lentils",
            name: "Чечевица",
            macros: Macros(calories: 116, protein: 9.0, fat: 0.4, carbs: 20.0),
            tags: ["legume"],
            groups: ["legumes"]
        )

        let foods = [rice, couscous, lentils]
        let foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let suggestions = SubstitutionEngine.suggest(
            originalFoodId: "rice",
            grams: 100,
            foods: foods,
            foodsById: foodsById,
            excludedAllergens: []
        )

        XCTAssertEqual(suggestions.first?.id, "couscous")
        XCTAssertGreaterThanOrEqual(suggestions.first?.score ?? 0, suggestions.last?.score ?? 0)
    }

    private func makeFood(
        id: String,
        name: String,
        macros: Macros,
        nutrients: [String: Double] = [:],
        tags: Set<String> = [],
        groups: Set<String> = [],
        allergens: Set<String> = []
    ) -> Food {
        Food(
            id: id,
            name: name,
            macrosPer100g: macros,
            nutrientsPer100g: nutrients,
            tags: tags,
            groups: groups,
            allergens: allergens
        )
    }
}
