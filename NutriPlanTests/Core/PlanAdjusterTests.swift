import Foundation
import Testing
@testable import NutriPlan

struct PlanAdjusterTests {
    @Test("Если пользователь заметно переел, цель на следующий день должна уменьшиться")
    func nextDayGoalDecreasesAfterOvereating() {
        let baseGoal = NutritionGoal(
            targetCalories: 2200,
            proteinGrams: 160,
            fatGrams: 70,
            carbsGrams: 220
        )

        let actual = NutritionSummary(
            macros: Macros(
                calories: 2700,
                protein: 185,
                fat: 90,
                carbs: 280
            ),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        #expect(adjustment.nextDayGoal.targetCalories < baseGoal.targetCalories)
    }

    @Test("Если пользователь сильно недоел, цель на следующий день должна увеличиться")
    func nextDayGoalIncreasesAfterUndereating() {
        let baseGoal = NutritionGoal(
            targetCalories: 2200,
            proteinGrams: 160,
            fatGrams: 70,
            carbsGrams: 220
        )

        let actual = NutritionSummary(
            macros: Macros(
                calories: 1500,
                protein: 110,
                fat: 45,
                carbs: 140
            ),
            nutrients: [:]
        )

        let adjustment = PlanAdjuster.recommend(
            baseGoal: baseGoal,
            actual: actual
        )

        #expect(adjustment.nextDayGoal.targetCalories > baseGoal.targetCalories)
    }
}
