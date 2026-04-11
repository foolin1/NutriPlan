import Foundation
import Testing
@testable import NutriPlan

struct PlanComparisonServiceTests {
    @Test("Сервис сравнения корректно считает отклонения по макронутриентам и железу")
    func comparisonCalculatesDeltas() throws {
        let planned = NutritionSummary(
            macros: Macros(
                calories: 2000,
                protein: 150,
                fat: 70,
                carbs: 220
            ),
            nutrients: ["iron": 8.0]
        )

        let actual = NutritionSummary(
            macros: Macros(
                calories: 1800,
                protein: 140,
                fat: 75,
                carbs: 210
            ),
            nutrients: ["iron": 6.5]
        )

        let comparison = PlanComparisonService.compare(
            planned: planned,
            actual: actual
        )

        #expect(abs(comparison.calories.delta - (-200)) < 0.001)
        #expect(abs(comparison.protein.delta - (-10)) < 0.001)
        #expect(abs(comparison.fat.delta - 5) < 0.001)
        #expect(abs(comparison.carbs.delta - (-10)) < 0.001)

        let iron = try #require(comparison.iron)
        #expect(abs(iron.delta - (-1.5)) < 0.001)
    }

    @Test("Если железо не задано ни в плане, ни по факту, сравнение по железу отсутствует")
    func comparisonOmitsIronWhenNotProvided() {
        let planned = NutritionSummary(
            macros: Macros(
                calories: 2000,
                protein: 150,
                fat: 70,
                carbs: 220
            ),
            nutrients: [:]
        )

        let actual = NutritionSummary(
            macros: Macros(
                calories: 1900,
                protein: 145,
                fat: 68,
                carbs: 215
            ),
            nutrients: [:]
        )

        let comparison = PlanComparisonService.compare(
            planned: planned,
            actual: actual
        )

        #expect(comparison.iron == nil)
    }
}
