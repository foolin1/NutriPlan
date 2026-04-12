import Foundation
import Testing
@testable import NutriPlan

@MainActor
struct DisplayTitleTests {
    @Test("Для неизменённого рецепта отображается исходное название")
    func displayTitleForOriginalRecipe() {
        let vm = PlanViewModel(
            foodRepo: TestFoodRepository(foods: TestDataFactory.foods),
            recipeRepo: TestRecipeRepository(recipes: TestDataFactory.highCalorieRecipes),
            sessionStore: TestSessionStore()
        )
        
        let title = vm.displayTitle(for: TestDataFactory.lunch)
        
        #expect(title == TestDataFactory.lunch.name)
    }
    
    @Test("Для изменённого рецепта заголовок собирается из основных ингредиентов")
    func displayTitleForModifiedRecipe() {
        let vm = PlanViewModel(
            foodRepo: TestFoodRepository(foods: TestDataFactory.foods),
            recipeRepo: TestRecipeRepository(recipes: TestDataFactory.highCalorieRecipes),
            sessionStore: TestSessionStore()
        )
        
        let modifiedRecipe = Recipe(
            id: "custom_modified",
            name: "Пользовательский рецепт",
            ingredients: [
                RecipeIngredient(foodId: "chicken_breast", grams: 220),
                RecipeIngredient(foodId: "rice", grams: 250),
                RecipeIngredient(foodId: "broccoli", grams: 80)
            ],
            cookTimeMinutes: 20,
            tags: ["lunch", "plate"],
            isModified: true
        )
        
        let title = vm.displayTitle(for: modifiedRecipe)
        
        #expect(title != modifiedRecipe.name)
        #expect(title.contains("Куриная грудка"))
        #expect(title.contains("рис"))
    }
}
