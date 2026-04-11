import Foundation
import Testing
@testable import NutriPlan

struct DayPlanCalorieTopUpServiceTests {
    @Test("Если дефицит маленький, дополнительный перекус не добавляется")
    func topUpDoesNotAddSnackWhenDeficitIsSmall() {
        let plan = DayPlan(
            meals: [
                PlannedMeal(type: .breakfast, recipe: TestDataFactory.breakfast),
                PlannedMeal(type: .lunch, recipe: TestDataFactory.lunch),
                PlannedMeal(type: .dinner, recipe: TestDataFactory.dinner),
                PlannedMeal(type: .snack, recipe: TestDataFactory.snack1)
            ]
        )

        let summary = TestDataFactory.summary(for: plan)
        let nearGoal = NutritionGoal(
            targetCalories: Int(summary.macros.calories.rounded()) + 150,
            proteinGrams: Int(summary.macros.protein.rounded()),
            fatGrams: Int(summary.macros.fat.rounded()),
            carbsGrams: Int(summary.macros.carbs.rounded())
        )

        let result = DayPlanCalorieTopUpService.topUpIfNeeded(
            dayPlan: plan,
            goal: nearGoal,
            allowedRecipes: TestDataFactory.highCalorieRecipes,
            foodsById: TestDataFactory.foodsById,
            nutrientFocus: .none
        )

        #expect(result.meals.count == plan.meals.count)
        #expect(result.meals.filter { $0.type == .snack }.count == 1)
    }

    @Test("Если в плане уже есть перекус, сервис добавляет не больше ещё одного")
    func topUpAddsAtMostOneMoreSnackWhenSnackAlreadyExists() {
        let plan = DayPlan(
            meals: [
                PlannedMeal(type: .breakfast, recipe: TestDataFactory.breakfast),
                PlannedMeal(type: .lunch, recipe: TestDataFactory.lunch),
                PlannedMeal(type: .dinner, recipe: TestDataFactory.dinner),
                PlannedMeal(type: .snack, recipe: TestDataFactory.snack1)
            ]
        )

        let before = TestDataFactory.summary(for: plan)

        let higherGoal = NutritionGoal(
            targetCalories: 2900,
            proteinGrams: 210,
            fatGrams: 95,
            carbsGrams: 300
        )

        let result = DayPlanCalorieTopUpService.topUpIfNeeded(
            dayPlan: plan,
            goal: higherGoal,
            allowedRecipes: TestDataFactory.highCalorieRecipes,
            foodsById: TestDataFactory.foodsById,
            nutrientFocus: .none
        )

        let after = TestDataFactory.summary(for: result)
        let snackCount = result.meals.filter { $0.type == .snack }.count

        #expect(after.macros.calories > before.macros.calories)
        #expect(snackCount <= 2)
        #expect(snackCount >= 1)
    }
}
