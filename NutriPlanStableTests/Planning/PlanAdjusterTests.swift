import XCTest
@testable import NutriPlan

final class PlanAdjusterTests: XCTestCase {

    func testRecommendReducesNextDayCaloriesAfterLargeExcess() {
        let baseGoal = NutritionGoal(
            targetCalories: 2200,
            proteinGrams: 140,
            fatGrams: 70,
            carbsGrams: 250
        )

        let actual = NutritionSummary(
            macros: Macros(calories: 2800, protein: 145, fat: 90, carbs: 320),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertLessThan(adjustment.nextDayGoal.targetCalories, baseGoal.targetCalories)
        XCTAssertEqual(adjustment.statusTitle, "На завтра стоит немного снизить калорийность")
        XCTAssertFalse(adjustment.hints.isEmpty)
    }

    func testRecommendIncreasesNextDayCaloriesAfterLargeDeficit() {
        let baseGoal = NutritionGoal(
            targetCalories: 2200,
            proteinGrams: 140,
            fatGrams: 70,
            carbsGrams: 250
        )

        let actual = NutritionSummary(
            macros: Macros(calories: 1700, protein: 130, fat: 55, carbs: 170),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertGreaterThan(adjustment.nextDayGoal.targetCalories, baseGoal.targetCalories)
        XCTAssertEqual(adjustment.statusTitle, "На завтра стоит немного повысить калорийность")
        XCTAssertFalse(adjustment.hints.isEmpty)
    }

    func testRecommendIncreasesProteinTargetWhenProteinWasTooLow() {
        let baseGoal = NutritionGoal(
            targetCalories: 2100,
            proteinGrams: 130,
            fatGrams: 65,
            carbsGrams: 255
        )

        let actual = NutritionSummary(
            macros: Macros(calories: 2050, protein: 100, fat: 64, carbs: 260),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertGreaterThan(adjustment.nextDayGoal.proteinGrams, baseGoal.proteinGrams)
        XCTAssertTrue(
            adjustment.hints.contains {
                $0.localizedCaseInsensitiveContains("белка")
            }
        )
    }

    func testRecommendReducesFatTargetWhenFatWasTooHigh() {
        let baseGoal = NutritionGoal(
            targetCalories: 2100,
            proteinGrams: 130,
            fatGrams: 70,
            carbsGrams: 240
        )

        let actual = NutritionSummary(
            macros: Macros(calories: 2200, protein: 128, fat: 95, carbs: 230),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertLessThan(adjustment.nextDayGoal.fatGrams, baseGoal.fatGrams)
        XCTAssertTrue(
            adjustment.hints.contains {
                $0.localizedCaseInsensitiveContains("жиры") ||
                $0.localizedCaseInsensitiveContains("постных")
            }
        )
    }

    func testRecommendKeepsCaloriesAboveMinimumFloor() {
        let baseGoal = NutritionGoal(
            targetCalories: 1300,
            proteinGrams: 100,
            fatGrams: 45,
            carbsGrams: 130
        )

        let actual = NutritionSummary(
            macros: Macros(calories: 2200, protein: 100, fat: 60, carbs: 250),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertGreaterThanOrEqual(adjustment.nextDayGoal.targetCalories, 1200)
    }

    func testRecommendReturnsCloseToTargetStatusWhenDeviationIsSmall() {
        let baseGoal = NutritionGoal(
            targetCalories: 2200,
            proteinGrams: 140,
            fatGrams: 70,
            carbsGrams: 250
        )

        let actual = NutritionSummary(
            macros: Macros(calories: 2260, protein: 145, fat: 72, carbs: 248),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertEqual(adjustment.statusTitle, "План выполнен близко к цели")
        XCTAssertFalse(adjustment.summary.isEmpty)
        XCTAssertFalse(adjustment.hints.isEmpty)
    }
}
