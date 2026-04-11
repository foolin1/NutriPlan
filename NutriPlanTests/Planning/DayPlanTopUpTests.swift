import Foundation
import Testing
@testable import NutriPlan

struct DayPlanTopUpTests {
    @Test("Добор калорий добавляет перекус, если базовый день сильно не дотягивает до цели")
    func topUpAddsSnackWhenNeeded() {
        let basePlan = DayPlan(
            meals: [
                PlannedMeal(type: .breakfast, recipe: TestDataFactory.breakfast),
                PlannedMeal(type: .lunch, recipe: TestDataFactory.lunch),
                PlannedMeal(type: .dinner, recipe: TestDataFactory.dinner)
            ]
        )

        let beforeSummary = TestDataFactory.summary(for: basePlan)

        let toppedUpPlan = DayPlanCalorieTopUpService.topUpIfNeeded(
            dayPlan: basePlan,
            goal: TestDataFactory.highGoal,
            allowedRecipes: TestDataFactory.highCalorieRecipes,
            foodsById: TestDataFactory.foodsById,
            nutrientFocus: .none
        )

        let afterSummary = TestDataFactory.summary(for: toppedUpPlan)

        #expect(afterSummary.macros.calories > beforeSummary.macros.calories)
        #expect(toppedUpPlan.meals.filter { $0.type == .snack }.count >= 1)
    }
}
