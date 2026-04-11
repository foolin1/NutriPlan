import Foundation
import Testing
@testable import NutriPlan

struct MealPlanBuilderTests {
    @Test("Построение плана с высокой целью добирает калории заметно выше базового уровня")
    func buildDayPlanForHighGoal() {
        let plan = MealPlanBuilder.buildDayPlan(
            goal: TestDataFactory.highGoal,
            recipes: TestDataFactory.highCalorieRecipes,
            foodsById: TestDataFactory.foodsById,
            excludedAllergens: [],
            excludedProducts: [],
            excludedGroups: [],
            nutrientFocus: .none
        )

        let summary = TestDataFactory.summary(for: plan)

        #expect(!plan.meals.isEmpty)
        #expect(summary.macros.calories >= 2200)
        #expect(plan.meals.filter { $0.type == .snack }.count >= 1)
    }

    @Test("Исключённые группы продуктов не должны попадать в итоговый план")
    func excludedGroupsAreRespected() {
        let plan = MealPlanBuilder.buildDayPlan(
            goal: TestDataFactory.highGoal,
            recipes: TestDataFactory.highCalorieRecipes,
            foodsById: TestDataFactory.foodsById,
            excludedAllergens: [],
            excludedProducts: [],
            excludedGroups: ["citrus"],
            nutrientFocus: .none
        )

        let usedFoodIds = Set(
            plan.meals.flatMap { $0.recipe.ingredients.map(\.foodId) }
        )

        #expect(!usedFoodIds.contains("orange"))
    }
}
