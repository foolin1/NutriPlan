import XCTest
@testable import NutriPlan

final class SubstitutionEngineEdgeCaseTests: XCTestCase {

    func testSuggestReturnsEmptyWhenOriginalFoodIsMissing() {
        let foods = makeFoods()
        let foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let result = SubstitutionEngine.suggest(
            originalFoodId: "missing_food",
            grams: 100,
            foods: foods,
            foodsById: foodsById,
            excludedAllergens: []
        )

        XCTAssertTrue(result.isEmpty)
    }

    func testSuggestReturnsEmptyWhenAllCompatibleCandidatesAreExcluded() {
        let foods = makeFoods()
        let foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let result = SubstitutionEngine.suggest(
            originalFoodId: "rice",
            grams: 100,
            foods: foods,
            foodsById: foodsById,
            excludedAllergens: [],
            excludedProducts: ["couscous", "buckwheat"],
            excludedGroups: ["legumes"]
        )

        XCTAssertTrue(result.isEmpty)
    }

    func testSuggestLimitsResultToEightCandidates() {
        let original = Food(
            id: "rice",
            name: "Рис",
            macrosPer100g: Macros(calories: 130, protein: 2.7, fat: 0.3, carbs: 28),
            nutrientsPer100g: [:],
            tags: ["grain"],
            groups: ["grain"],
            allergens: []
        )

        let candidates = (1...12).map { index in
            Food(
                id: "grain_\(index)",
                name: "Крупа \(index)",
                macrosPer100g: Macros(
                    calories: 120 + Double(index),
                    protein: 3,
                    fat: 0.5,
                    carbs: 25 + Double(index) * 0.2
                ),
                nutrientsPer100g: [:],
                tags: ["grain"],
                groups: ["grain"],
                allergens: []
            )
        }

        let foods = [original] + candidates
        let foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let result = SubstitutionEngine.suggest(
            originalFoodId: "rice",
            grams: 100,
            foods: foods,
            foodsById: foodsById,
            excludedAllergens: []
        )

        XCTAssertEqual(result.count, 8)
    }

    func testSuggestAllowsFishAsCompatibleAlternativeForMeat() {
        let foods = makeFoods()
        let foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let result = SubstitutionEngine.suggest(
            originalFoodId: "chicken",
            grams: 150,
            foods: foods,
            foodsById: foodsById,
            excludedAllergens: []
        )

        let ids = Set(result.map(\.id))

        XCTAssertTrue(ids.contains("salmon") || ids.contains("lean_beef"))
    }

    func testSuggestAppliesRequiredTags() {
        let foods = makeFoods()
        let foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let result = SubstitutionEngine.suggest(
            originalFoodId: "rice",
            grams: 100,
            foods: foods,
            foodsById: foodsById,
            excludedAllergens: [],
            requiredTags: ["gluten_free"]
        )

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { candidate in
            foodsById[candidate.id]?.tags.contains("gluten_free") == true
        })
    }

    func testSuggestComputesDeltaMacrosForRequestedPortion() {
        let foods = makeFoods()
        let foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let result = SubstitutionEngine.suggest(
            originalFoodId: "rice",
            grams: 200,
            foods: foods,
            foodsById: foodsById,
            excludedAllergens: []
        )

        let couscous = result.first { $0.id == "couscous" }

        XCTAssertNotNil(couscous)

        // Рис на 200 г: 260 ккал.
        // Кускус на 200 г: 224 ккал.
        // Ожидаемая разница: -36 ккал.
        XCTAssertEqual(couscous?.deltaMacros.calories ?? 0, -36, accuracy: 0.01)
    }

    private func makeFoods() -> [Food] {
        [
            Food(
                id: "rice",
                name: "Рис",
                macrosPer100g: Macros(calories: 130, protein: 2.7, fat: 0.3, carbs: 28),
                nutrientsPer100g: [:],
                tags: ["grain", "gluten_free"],
                groups: ["grain"],
                allergens: []
            ),
            Food(
                id: "couscous",
                name: "Кускус",
                macrosPer100g: Macros(calories: 112, protein: 3.8, fat: 0.2, carbs: 23),
                nutrientsPer100g: [:],
                tags: ["grain"],
                groups: ["grain"],
                allergens: []
            ),
            Food(
                id: "buckwheat",
                name: "Гречка",
                macrosPer100g: Macros(calories: 110, protein: 4.0, fat: 1.0, carbs: 21),
                nutrientsPer100g: [:],
                tags: ["grain", "gluten_free"],
                groups: ["grain"],
                allergens: []
            ),
            Food(
                id: "lentils",
                name: "Чечевица",
                macrosPer100g: Macros(calories: 116, protein: 9, fat: 0.4, carbs: 20),
                nutrientsPer100g: ["iron": 3.3],
                tags: ["legume", "gluten_free"],
                groups: ["legumes"],
                allergens: []
            ),
            Food(
                id: "chicken",
                name: "Куриная грудка",
                macrosPer100g: Macros(calories: 165, protein: 31, fat: 3.6, carbs: 0),
                nutrientsPer100g: [:],
                tags: ["meat", "high_protein"],
                groups: ["poultry"],
                allergens: []
            ),
            Food(
                id: "lean_beef",
                name: "Постная говядина",
                macrosPer100g: Macros(calories: 170, protein: 30, fat: 5, carbs: 0),
                nutrientsPer100g: ["iron": 2.6],
                tags: ["meat", "high_protein"],
                groups: ["red_meat"],
                allergens: []
            ),
            Food(
                id: "salmon",
                name: "Лосось",
                macrosPer100g: Macros(calories: 208, protein: 20, fat: 13, carbs: 0),
                nutrientsPer100g: [:],
                tags: ["seafood", "high_protein"],
                groups: ["seafood"],
                allergens: []
            )
        ]
    }
}
