import XCTest
@testable import NutriPlan

final class DayPlanOptimizerTests: XCTestCase {

    func testBuildOptimizedDayPlanReturnsEmptyWhenCandidatePoolsAreEmpty() {
        let plan = DayPlanOptimizer.buildOptimizedDayPlan(
            goal: NutritionGoal(
                targetCalories: 1800,
                proteinGrams: 100,
                fatGrams: 55,
                carbsGrams: 220
            ),
            candidatePools: [:],
            foodsById: makeFoods(),
            nutrientFocus: .none
        )

        XCTAssertTrue(plan.meals.isEmpty)
    }

    func testBuildOptimizedDayPlanSortsMealsByNaturalMealOrder() {
        let foodsById = makeFoods()

        let dinner = makeRecipe(
            id: "dinner",
            name: "Ужин",
            foodId: "turkey",
            grams: 150,
            tags: ["dinner"]
        )
        let breakfast = makeRecipe(
            id: "breakfast",
            name: "Завтрак",
            foodId: "oats",
            grams: 60,
            tags: ["breakfast"]
        )
        let lunch = makeRecipe(
            id: "lunch",
            name: "Обед",
            foodId: "chicken",
            grams: 150,
            tags: ["lunch"]
        )

        let plan = DayPlanOptimizer.buildOptimizedDayPlan(
            goal: nil,
            candidatePools: [
                .dinner: [dinner],
                .breakfast: [breakfast],
                .lunch: [lunch]
            ],
            foodsById: foodsById,
            nutrientFocus: .none
        )

        XCTAssertEqual(plan.meals.map(\.type), [.breakfast, .lunch, .dinner])
    }

    func testBuildOptimizedDayPlanDoesNotReuseSameRecipeAcrossMealTypes() {
        let foodsById = makeFoods()

        let sharedRecipe = makeRecipe(
            id: "shared_recipe",
            name: "Общее блюдо",
            foodId: "rice",
            grams: 150,
            tags: ["breakfast", "lunch"]
        )
        let lunchAlternative = makeRecipe(
            id: "lunch_alternative",
            name: "Курица",
            foodId: "chicken",
            grams: 150,
            tags: ["lunch"]
        )

        let plan = DayPlanOptimizer.buildOptimizedDayPlan(
            goal: nil,
            candidatePools: [
                .breakfast: [sharedRecipe],
                .lunch: [sharedRecipe, lunchAlternative]
            ],
            foodsById: foodsById,
            nutrientFocus: .none
        )

        let recipeIds = plan.meals.map { $0.recipe.id }
        let uniqueRecipeIds = Set(recipeIds)

        XCTAssertEqual(recipeIds.count, uniqueRecipeIds.count)
    }

    func testEvaluateReturnsActualMacrosAndMealCount() {
        let foodsById = makeFoods()

        let breakfast = PlannedMeal(
            type: .breakfast,
            recipe: makeRecipe(
                id: "breakfast",
                name: "Овсянка",
                foodId: "oats",
                grams: 100,
                tags: ["breakfast"]
            )
        )
        let lunch = PlannedMeal(
            type: .lunch,
            recipe: makeRecipe(
                id: "lunch",
                name: "Курица",
                foodId: "chicken",
                grams: 100,
                tags: ["lunch"]
            )
        )

        let breakdown = DayPlanOptimizer.evaluate(
            meals: [breakfast, lunch],
            goal: NutritionGoal(
                targetCalories: 1800,
                proteinGrams: 100,
                fatGrams: 55,
                carbsGrams: 220
            ),
            foodsById: foodsById,
            nutrientFocus: .none
        )

        XCTAssertEqual(breakdown.mealCount, 2)
        XCTAssertEqual(breakdown.actualCalories, 535, accuracy: 0.01)
        XCTAssertEqual(breakdown.actualProtein, 44, accuracy: 0.01)
        XCTAssertEqual(breakdown.actualFat, 10.6, accuracy: 0.01)
        XCTAssertEqual(breakdown.actualCarbs, 60, accuracy: 0.01)
    }

    func testEvaluateIncreasesCoverageBonusWhenMoreMealsArePresent() {
        let foodsById = makeFoods()

        let oneMeal = [
            PlannedMeal(
                type: .breakfast,
                recipe: makeRecipe(
                    id: "breakfast",
                    name: "Овсянка",
                    foodId: "oats",
                    grams: 100,
                    tags: ["breakfast"]
                )
            )
        ]

        let twoMeals = oneMeal + [
            PlannedMeal(
                type: .lunch,
                recipe: makeRecipe(
                    id: "lunch",
                    name: "Курица",
                    foodId: "chicken",
                    grams: 100,
                    tags: ["lunch"]
                )
            )
        ]

        let oneMealBreakdown = DayPlanOptimizer.evaluate(
            meals: oneMeal,
            goal: nil,
            foodsById: foodsById,
            nutrientFocus: .none
        )

        let twoMealBreakdown = DayPlanOptimizer.evaluate(
            meals: twoMeals,
            goal: nil,
            foodsById: foodsById,
            nutrientFocus: .none
        )

        XCTAssertGreaterThan(
            twoMealBreakdown.coverageBonus,
            oneMealBreakdown.coverageBonus
        )
    }

    private func makeRecipe(
        id: String,
        name: String,
        foodId: String,
        grams: Double,
        tags: Set<String>
    ) -> Recipe {
        Recipe(
            id: id,
            name: name,
            ingredients: [
                RecipeIngredient(foodId: foodId, grams: grams)
            ],
            cookTimeMinutes: 15,
            tags: tags,
            isModified: false
        )
    }

    private func makeFoods() -> [String: Food] {
        [
            "oats": Food(
                id: "oats",
                name: "Овсянка",
                macrosPer100g: Macros(calories: 370, protein: 13, fat: 7, carbs: 60),
                nutrientsPer100g: ["iron": 4.0],
                tags: ["grain"],
                groups: ["grain"],
                allergens: []
            ),
            "rice": Food(
                id: "rice",
                name: "Рис",
                macrosPer100g: Macros(calories: 130, protein: 2.7, fat: 0.3, carbs: 28),
                nutrientsPer100g: [:],
                tags: ["grain"],
                groups: ["grain"],
                allergens: []
            ),
            "chicken": Food(
                id: "chicken",
                name: "Курица",
                macrosPer100g: Macros(calories: 165, protein: 31, fat: 3.6, carbs: 0),
                nutrientsPer100g: [:],
                tags: ["meat", "high_protein"],
                groups: ["poultry"],
                allergens: []
            ),
            "turkey": Food(
                id: "turkey",
                name: "Индейка",
                macrosPer100g: Macros(calories: 135, protein: 29, fat: 1.6, carbs: 0),
                nutrientsPer100g: [:],
                tags: ["meat", "high_protein"],
                groups: ["poultry"],
                allergens: []
            )
        ]
    }
}
