import XCTest
@testable import NutriPlan

final class PerformanceSmokeTests: XCTestCase {

    private var foods: [Food] = []
    private var foodsById: [String: Food] = [:]
    private var recipes: [Recipe] = []
    private var goal: NutritionGoal!

    override func setUp() {
        super.setUp()

        foods = makeFoods(count: 300)
        foodsById = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })
        recipes = makeRecipes(count: 800, foods: foods)

        goal = NutritionGoal(
            targetCalories: 2200,
            proteinGrams: 140,
            fatGrams: 70,
            carbsGrams: 260
        )
    }

    func testGoalCalculationPerformance() {
        let profile = UserProfile(
            sex: .male,
            age: 25,
            heightCm: 180,
            weightKg: 80,
            activityLevel: .moderate,
            goalType: .maintainWeight
        )

        measureWithStableOptions {
            _ = GoalCalculator.calculate(for: profile)
        }
    }

    func testDayPlanBuildingPerformance() {
        measureWithStableOptions {
            _ = MealPlanBuilder.buildDayPlan(
                goal: self.goal,
                recipes: self.recipes,
                foodsById: self.foodsById,
                excludedAllergens: [],
                excludedProducts: [],
                excludedGroups: [],
                nutrientFocus: .iron
            )
        }
    }

    func testSubstitutionSearchPerformance() {
        let originalFoodId = foods.first?.id ?? "food_0"

        measureWithStableOptions {
            _ = SubstitutionEngine.suggest(
                originalFoodId: originalFoodId,
                grams: 100,
                foods: self.foods,
                foodsById: self.foodsById,
                excludedAllergens: [],
                excludedProducts: [],
                excludedGroups: [],
                requiredTags: []
            )
        }
    }

    func testShoppingListBuildingPerformance() {
        let selectedRecipes = Array(recipes.prefix(12))

        measureWithStableOptions {
            _ = ShoppingListBuilder.build(
                recipes: selectedRecipes,
                foodsById: self.foodsById
            )
        }
    }

    private func measureWithStableOptions(_ block: @escaping () -> Void) {
        let options = XCTMeasureOptions()
        options.iterationCount = 10

        measure(
            metrics: [XCTClockMetric()],
            options: options,
            block: block
        )
    }

    private func makeFoods(count: Int) -> [Food] {
        (0..<count).map { index in
            let category = index % 4

            let tags: Set<String>
            let groups: Set<String>
            let allergens: Set<String>

            switch category {
            case 0:
                tags = ["grain", "gluten_free"]
                groups = ["grain"]
                allergens = []
            case 1:
                tags = ["meat", "high_protein"]
                groups = ["poultry"]
                allergens = []
            case 2:
                tags = ["vegetable"]
                groups = ["vegetable"]
                allergens = []
            default:
                tags = ["fruit"]
                groups = ["fruit"]
                allergens = []
            }

            return Food(
                id: "food_\(index)",
                name: "Продукт \(index)",
                macrosPer100g: Macros(
                    calories: Double(80 + (index % 220)),
                    protein: Double(2 + (index % 28)),
                    fat: Double(1 + (index % 18)),
                    carbs: Double(5 + (index % 60))
                ),
                nutrientsPer100g: [
                    "iron": Double(index % 8),
                    "vitamin_c": Double(index % 30),
                    "calcium": Double(index % 120),
                    "magnesium": Double(index % 60)
                ],
                tags: tags,
                groups: groups,
                allergens: allergens
            )
        }
    }

    private func makeRecipes(count: Int, foods: [Food]) -> [Recipe] {
        let mealTags = ["breakfast", "lunch", "dinner", "snack"]

        return (0..<count).map { recipeIndex in
            let ingredients = (0..<4).map { offset in
                let food = foods[(recipeIndex + offset) % foods.count]

                return RecipeIngredient(
                    foodId: food.id,
                    grams: Double(60 + ((recipeIndex + offset) % 120))
                )
            }

            return Recipe(
                id: "recipe_\(recipeIndex)",
                name: "Рецепт \(recipeIndex)",
                ingredients: ingredients,
                cookTimeMinutes: 15 + recipeIndex % 30,
                tags: [mealTags[recipeIndex % mealTags.count]],
                isModified: false
            )
        }
    }
}
