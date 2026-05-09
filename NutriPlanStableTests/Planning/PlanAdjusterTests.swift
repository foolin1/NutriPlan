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
            macros: Macros(
                calories: 2800,
                protein: 145,
                fat: 90,
                carbs: 320
            ),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertLessThan(
            adjustment.nextDayGoal.targetCalories,
            baseGoal.targetCalories
        )
        XCTAssertEqual(
            adjustment.statusTitle,
            "На завтра стоит снизить калорийность"
        )
        XCTAssertFalse(adjustment.summary.isEmpty)
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
            macros: Macros(
                calories: 1700,
                protein: 130,
                fat: 55,
                carbs: 170
            ),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertGreaterThan(
            adjustment.nextDayGoal.targetCalories,
            baseGoal.targetCalories
        )
        XCTAssertEqual(
            adjustment.statusTitle,
            "На завтра стоит повысить калорийность"
        )
        XCTAssertFalse(adjustment.summary.isEmpty)
        XCTAssertFalse(adjustment.hints.isEmpty)
    }

    func testAdaptiveCorrectionUsesFortyPercentForMediumExcess() {
        let baseGoal = NutritionGoal(
            targetCalories: 2000,
            proteinGrams: 120,
            fatGrams: 65,
            carbsGrams: 240
        )

        let actual = NutritionSummary(
            macros: Macros(
                calories: 2500,
                protein: 120,
                fat: 65,
                carbs: 365
            ),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        // Отклонение: +500 ккал.
        // Диапазон 300...700 ккал -> компенсация 40%.
        // 500 * 0.40 = 200 ккал.
        // 2000 - 200 = 1800 ккал.
        XCTAssertEqual(adjustment.nextDayGoal.targetCalories, 1800)
        XCTAssertTrue(adjustment.summary.contains("40%"))
        XCTAssertTrue(adjustment.summary.contains("2000 → 1800"))
    }

    func testAdaptiveCorrectionDoesNotChangeCaloriesForSmallDeviation() {
        let baseGoal = NutritionGoal(
            targetCalories: 2000,
            proteinGrams: 120,
            fatGrams: 65,
            carbsGrams: 240
        )

        let actual = NutritionSummary(
            macros: Macros(
                calories: 2070,
                protein: 124,
                fat: 67,
                carbs: 245
            ),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertEqual(adjustment.nextDayGoal.targetCalories, 2000)
        XCTAssertEqual(adjustment.statusTitle, "План выполнен близко к цели")
        XCTAssertTrue(adjustment.summary.contains("допустимом диапазоне"))
    }

    func testAdaptiveCorrectionLimitsVeryLargeExcessByDynamicShift() {
        let baseGoal = NutritionGoal(
            targetCalories: 2000,
            proteinGrams: 120,
            fatGrams: 65,
            carbsGrams: 240
        )

        let actual = NutritionSummary(
            macros: Macros(
                calories: 3500,
                protein: 120,
                fat: 65,
                carbs: 615
            ),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        // Отклонение: +1500 ккал.
        // Компенсация 50% дала бы 750 ккал,
        // но для цели 2000 ккал динамический предел равен 300 ккал.
        // Итог: 2000 - 300 = 1700 ккал.
        XCTAssertEqual(adjustment.nextDayGoal.targetCalories, 1700)
    }

    func testAdaptiveCorrectionLimitsVeryLargeDeficitByDynamicShift() {
        let baseGoal = NutritionGoal(
            targetCalories: 2000,
            proteinGrams: 120,
            fatGrams: 65,
            carbsGrams: 240
        )

        let actual = NutritionSummary(
            macros: Macros(
                calories: 1000,
                protein: 120,
                fat: 65,
                carbs: 0
            ),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        // Отклонение: -1000 ккал.
        // Компенсация 50% дала бы +500 ккал к цели,
        // но для цели 2000 ккал динамический предел равен 300 ккал.
        // Итог: 2000 + 300 = 2300 ккал.
        XCTAssertEqual(adjustment.nextDayGoal.targetCalories, 2300)
    }

    func testRecommendIncreasesProteinTargetWhenProteinWasTooLow() {
        let baseGoal = NutritionGoal(
            targetCalories: 2100,
            proteinGrams: 130,
            fatGrams: 65,
            carbsGrams: 255
        )

        let actual = NutritionSummary(
            macros: Macros(
                calories: 2050,
                protein: 100,
                fat: 64,
                carbs: 260
            ),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertGreaterThan(
            adjustment.nextDayGoal.proteinGrams,
            baseGoal.proteinGrams
        )
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
            macros: Macros(
                calories: 2200,
                protein: 128,
                fat: 95,
                carbs: 230
            ),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertLessThan(
            adjustment.nextDayGoal.fatGrams,
            baseGoal.fatGrams
        )
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
            macros: Macros(
                calories: 2200,
                protein: 100,
                fat: 60,
                carbs: 250
            ),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertGreaterThanOrEqual(
            adjustment.nextDayGoal.targetCalories,
            1200
        )
    }

    func testRecommendReturnsCloseToTargetStatusWhenDeviationIsSmall() {
        let baseGoal = NutritionGoal(
            targetCalories: 2200,
            proteinGrams: 140,
            fatGrams: 70,
            carbsGrams: 250
        )

        let actual = NutritionSummary(
            macros: Macros(
                calories: 2260,
                protein: 145,
                fat: 72,
                carbs: 248
            ),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        XCTAssertEqual(
            adjustment.statusTitle,
            "План выполнен близко к цели"
        )
        XCTAssertEqual(adjustment.nextDayGoal.targetCalories, 2200)
        XCTAssertFalse(adjustment.summary.isEmpty)
        XCTAssertFalse(adjustment.hints.isEmpty)
    }
}
