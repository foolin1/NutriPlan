import Foundation
import Testing
@testable import NutriPlan

@MainActor
struct DiarySyncTests {
    @Test("После замены ингредиента у записанного блюда дневник синхронизируется")
    func diaryEntryUpdatesAfterSubstitution() throws {
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
        
        let breakfastMeal = try #require(
            vm.dayPlan.meals.first(where: { meal in
                meal.type == .breakfast &&
                meal.recipe.ingredients.contains(where: { $0.foodId == "banana" })
            })
        )
        
        let bananaIndex = try #require(
            breakfastMeal.recipe.ingredients.firstIndex(where: { $0.foodId == "banana" })
        )
        
        vm.addMealToDiary(mealId: breakfastMeal.id)
        vm.applySubstitution(
            mealId: breakfastMeal.id,
            ingredientIndex: bananaIndex,
            newFoodId: "apple"
        )
        
        let updatedEntry = try #require(
            vm.diaryDay.entries.first(where: { $0.mealId == breakfastMeal.id })
        )
        
        let foodIds = updatedEntry.recipe.ingredients.map(\.foodId)
        
        #expect(foodIds.contains("apple"))
        #expect(!foodIds.contains("banana"))
        #expect(updatedEntry.recipe.isModified == true)
    }
    
    @Test("После изменения порции у записанного блюда дневник получает обновлённую граммовку")
    func diaryEntryUpdatesAfterPortionChange() throws {
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
        
        let lunchMeal = try #require(
            vm.dayPlan.meals.first(where: { $0.type == .lunch })
        )
        
        let ingredientIndex = 0
        let beforeGrams = lunchMeal.recipe.ingredients[ingredientIndex].grams
        
        vm.addMealToDiary(mealId: lunchMeal.id)
        
        vm.increaseIngredientPortion(
            mealId: lunchMeal.id,
            ingredientIndex: ingredientIndex,
            step: 25,
            minGrams: 25,
            maxGrams: 500
        )
        
        let updatedEntry = try #require(
            vm.diaryDay.entries.first(where: { $0.mealId == lunchMeal.id })
        )
        
        let updatedGrams = updatedEntry.recipe.ingredients[ingredientIndex].grams
        
        let expectedGrams = ((beforeGrams + 25) / 25).rounded() * 25
        
        #expect(updatedGrams == expectedGrams)
        #expect(updatedGrams > beforeGrams)
        #expect(updatedEntry.recipe.isModified == true)
    }
}
