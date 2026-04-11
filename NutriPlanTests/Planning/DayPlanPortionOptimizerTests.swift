import Foundation
import Testing
@testable import NutriPlan

struct DayPlanPortionOptimizerTests {
    @Test("Оптимизатор порций увеличивает калории и не уменьшает число блюд")
    func portionOptimizerRaisesCalories() {
        let basePlan = DayPlan(
            meals: [
                PlannedMeal(type: .breakfast, recipe: TestDataFactory.breakfast),
                PlannedMeal(type: .lunch, recipe: TestDataFactory.lunch),
                PlannedMeal(type: .dinner, recipe: TestDataFactory.dinner)
            ]
        )

        let before = TestDataFactory.summary(for: basePlan)

        let optimized = DayPlanPortionOptimizer.optimize(
            dayPlan: basePlan,
            goal: TestDataFactory.highGoal,
            foodsById: TestDataFactory.foodsById,
            nutrientFocus: .none
        )

        let after = TestDataFactory.summary(for: optimized)

        #expect(optimized.meals.count == basePlan.meals.count)
        #expect(after.macros.calories > before.macros.calories)
        #expect(after.macros.protein >= before.macros.protein)
    }
}
