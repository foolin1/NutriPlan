import Foundation
import Testing
@testable import NutriPlan

struct SubstitutionEngineTests {
    @Test("Замены не должны включать продукты из другой категории и явно исключённые продукты")
    func excludedProductsAndCategoryAreRespected() {
        let foods: [Food] = [
            TestDataFactory.chicken,
            TestDataFactory.turkey,
            TestDataFactory.beef,
            TestDataFactory.rice
        ]

        let foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let candidates = SubstitutionEngine.suggest(
            originalFoodId: "chicken_breast",
            grams: 100,
            foods: foods,
            foodsById: foodsById,
            excludedAllergens: [],
            excludedProducts: ["turkey"],
            excludedGroups: [],
            requiredTags: []
        )

        #expect(!candidates.isEmpty)
        #expect(candidates.allSatisfy { $0.id != "turkey_breast" })
        #expect(candidates.allSatisfy { $0.id != "rice" })
        #expect(candidates.first?.id == "lean_beef")
    }
}
