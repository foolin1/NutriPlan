import Foundation
import Testing
@testable import NutriPlan

@MainActor
struct PlanViewModelShuffleTests {
    @Test("Shuffle тоже проходит финальную доводку плана и уважает ограничения")
    func shuffleUsesFinalizationAndKeepsRestrictions() {
        let foodRepo = TestFoodRepository(foods: TestDataFactory.foods)
        let recipeRepo = TestRecipeRepository(recipes: TestDataFactory.highCalorieRecipes)
        let sessionStore = TestSessionStore()

        let vm = PlanViewModel(
            foodRepo: foodRepo,
            recipeRepo: recipeRepo,
            sessionStore: sessionStore
        )

        let profile = UserProfile(
            sex: .male,
            age: 30,
            heightCm: 180,
            weightKg: 80,
            activityLevel: .moderate,
            goalType: .maintainWeight,
            nutrientFocus: .none,
            excludedAllergens: [],
            excludedProducts: [],
            excludedGroups: ["citrus"]
        )

        vm.configureSession(profile: profile, goal: TestDataFactory.highGoal)
        vm.shuffleDayPlan(goal: TestDataFactory.highGoal)

        let summary = vm.daySummary()
        let usedFoodIds = Set(
            vm.dayPlan.meals.flatMap { $0.recipe.ingredients.map(\.foodId) }
        )

        #expect(!vm.dayPlan.meals.isEmpty)
        #expect(summary.macros.calories >= 2200)
        #expect(!usedFoodIds.contains("orange"))
    }
}
