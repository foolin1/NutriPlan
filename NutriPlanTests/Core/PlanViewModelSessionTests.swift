import Foundation
import Testing
@testable import NutriPlan

@MainActor
struct PlanViewModelSessionTests {
    @Test("План и дневник восстанавливаются из session store при одинаковом профиле")
    func sessionIsRestoredForSameSignature() throws {
        let sessionStore = TestSessionStore()
        let foodRepo = TestFoodRepository(foods: TestDataFactory.foods)
        let recipeRepo = TestRecipeRepository(recipes: TestDataFactory.highCalorieRecipes)

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
            excludedGroups: []
        )

        let vm1 = PlanViewModel(
            foodRepo: foodRepo,
            recipeRepo: recipeRepo,
            sessionStore: sessionStore
        )

        vm1.configureSession(profile: profile, goal: TestDataFactory.highGoal)

        let firstMeal = try #require(vm1.dayPlan.meals.first)
        vm1.addMealToDiary(mealId: firstMeal.id)

        let firstPlanCount = vm1.dayPlan.meals.count
        let firstDiaryCount = vm1.diaryDay.entries.count
        let firstCalories = vm1.daySummary().macros.calories

        let vm2 = PlanViewModel(
            foodRepo: foodRepo,
            recipeRepo: recipeRepo,
            sessionStore: sessionStore
        )

        vm2.configureSession(profile: profile, goal: TestDataFactory.highGoal)

        #expect(vm2.dayPlan.meals.count == firstPlanCount)
        #expect(vm2.diaryDay.entries.count == firstDiaryCount)
        #expect(abs(vm2.daySummary().macros.calories - firstCalories) < 0.001)
    }

    @Test("resetSession очищает состояние и удаляет сохранённую сессию")
    func resetSessionClearsStateAndStorage() throws {
        let sessionStore = TestSessionStore()
        let foodRepo = TestFoodRepository(foods: TestDataFactory.foods)
        let recipeRepo = TestRecipeRepository(recipes: TestDataFactory.highCalorieRecipes)

        let profile = UserProfile(
            sex: .male,
            age: 30,
            heightCm: 180,
            weightKg: 80,
            activityLevel: .moderate,
            goalType: .maintainWeight
        )

        let vm = PlanViewModel(
            foodRepo: foodRepo,
            recipeRepo: recipeRepo,
            sessionStore: sessionStore
        )

        vm.configureSession(profile: profile, goal: TestDataFactory.highGoal)

        let firstMeal = try #require(vm.dayPlan.meals.first)
        vm.addMealToDiary(mealId: firstMeal.id)

        #expect(!vm.dayPlan.meals.isEmpty)
        #expect(!vm.diaryDay.entries.isEmpty)
        #expect(sessionStore.load() != nil)

        vm.resetSession()

        #expect(vm.dayPlan.meals.isEmpty)
        #expect(vm.diaryDay.entries.isEmpty)
        #expect(sessionStore.load() == nil)
    }
}
