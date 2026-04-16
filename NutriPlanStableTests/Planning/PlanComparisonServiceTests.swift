import XCTest
@testable import NutriPlan

final class PlanComparisonServiceTests: XCTestCase {

    func testCompareBuildsMainMacroMetrics() {
        let planned = NutritionSummary(
            macros: Macros(calories: 2100, protein: 140, fat: 70, carbs: 220),
            nutrients: [:]
        )

        let actual = NutritionSummary(
            macros: Macros(calories: 1950, protein: 130, fat: 65, carbs: 205),
            nutrients: [:]
        )

        let comparison = PlanComparisonService.compare(
            planned: planned,
            actual: actual
        )

        XCTAssertEqual(comparison.calories.title, "Calories")
        XCTAssertEqual(comparison.calories.unit, "kcal")
        XCTAssertEqual(comparison.calories.planned, 2100)
        XCTAssertEqual(comparison.calories.actual, 1950)
        XCTAssertEqual(comparison.calories.delta, -150)

        XCTAssertEqual(comparison.protein.title, "Protein")
        XCTAssertEqual(comparison.protein.unit, "g")
        XCTAssertEqual(comparison.protein.planned, 140)
        XCTAssertEqual(comparison.protein.actual, 130)
        XCTAssertEqual(comparison.protein.delta, -10)

        XCTAssertEqual(comparison.fat.title, "Fat")
        XCTAssertEqual(comparison.carbs.title, "Carbs")
    }

    func testCompareIncludesIronMetricWhenPresentInPlanOrFact() {
        let planned = NutritionSummary(
            macros: Macros(calories: 2000, protein: 120, fat: 60, carbs: 240),
            nutrients: ["iron": 12.0]
        )

        let actual = NutritionSummary(
            macros: Macros(calories: 1900, protein: 110, fat: 58, carbs: 230),
            nutrients: ["iron": 8.5]
        )

        let comparison = PlanComparisonService.compare(
            planned: planned,
            actual: actual
        )

        XCTAssertNotNil(comparison.iron)
        XCTAssertEqual(comparison.iron?.title, "Iron")
        XCTAssertEqual(comparison.iron?.unit, "mg")
        XCTAssertEqual(comparison.iron?.planned, 12.0)
        XCTAssertEqual(comparison.iron?.actual, 8.5)
        XCTAssertEqual(comparison.iron?.delta, -3.5)
    }

    func testCompareOmitsIronMetricWhenAbsentEverywhere() {
        let planned = NutritionSummary(
            macros: Macros(calories: 2000, protein: 120, fat: 60, carbs: 240),
            nutrients: [:]
        )

        let actual = NutritionSummary(
            macros: Macros(calories: 1900, protein: 110, fat: 58, carbs: 230),
            nutrients: [:]
        )

        let comparison = PlanComparisonService.compare(
            planned: planned,
            actual: actual
        )

        XCTAssertNil(comparison.iron)
    }

    func testCompletionPercentIsCalculatedCorrectly() {
        let metric = PlanComparisonMetric(
            title: "Protein",
            unit: "g",
            planned: 100,
            actual: 75
        )

        XCTAssertEqual(metric.delta, -25)
        XCTAssertEqual(metric.completionPercent, 75)
    }

    func testCompletionPercentIsZeroWhenPlannedIsZero() {
        let metric = PlanComparisonMetric(
            title: "Calories",
            unit: "kcal",
            planned: 0,
            actual: 500
        )

        XCTAssertEqual(metric.completionPercent, 0)
    }
}
