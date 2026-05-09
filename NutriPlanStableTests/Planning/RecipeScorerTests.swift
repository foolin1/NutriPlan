import XCTest
@testable import NutriPlan

final class RecipeScorerTests: XCTestCase {

    func testMealTagReturnsExpectedTagForEachMealType() {
        XCTAssertEqual(RecipeScorer.mealTag(for: .breakfast), "breakfast")
        XCTAssertEqual(RecipeScorer.mealTag(for: .lunch), "lunch")
        XCTAssertEqual(RecipeScorer.mealTag(for: .dinner), "dinner")
        XCTAssertEqual(RecipeScorer.mealTag(for: .snack), "snack")
    }

    func testEvaluateUsesMealShareForBreakfastTarget() {
        let foodsById = makeFoods()
        let recipe = makeRecipe(
            id: "oatmeal",
            name: "Овсянка",
            foodId: "oats",
            grams: 100,
            tags: ["breakfast"]
        )

        let score = RecipeScorer.evaluate(
            recipe: recipe,
            mealType: .breakfast,
            goal: NutritionGoal(
                targetCalories: 2000,
                proteinGrams: 120,
                fatGrams: 70,
                carbsGrams: 250
            ),
            foodsById: foodsById,
            nutrientFocus: .none
        )

        XCTAssertEqual(score.mealTargetCalories, 500, accuracy: 0.01)
        XCTAssertEqual(score.mealTargetProtein, 30, accuracy: 0.01)
        XCTAssertEqual(score.mealTargetFat, 17.5, accuracy: 0.01)
        XCTAssertEqual(score.mealTargetCarbs, 62.5, accuracy: 0.01)
    }

    func testEvaluateUsesMealShareForLunchTarget() {
        let foodsById = makeFoods()
        let recipe = makeRecipe(
            id: "chicken",
            name: "Курица",
            foodId: "chicken",
            grams: 150,
            tags: ["lunch"]
        )

        let score = RecipeScorer.evaluate(
            recipe: recipe,
            mealType: .lunch,
            goal: NutritionGoal(
                targetCalories: 2000,
                proteinGrams: 120,
                fatGrams: 70,
                carbsGrams: 250
            ),
            foodsById: foodsById,
            nutrientFocus: .none
        )

        XCTAssertEqual(score.mealTargetCalories, 700, accuracy: 0.01)
        XCTAssertEqual(score.mealTargetProtein, 42, accuracy: 0.01)
        XCTAssertEqual(score.mealTargetFat, 24.5, accuracy: 0.01)
        XCTAssertEqual(score.mealTargetCarbs, 87.5, accuracy: 0.01)
    }

    func testEvaluateAddsTagBonusForMatchingMealType() {
        let foodsById = makeFoods()
        let taggedRecipe = makeRecipe(
            id: "tagged_oatmeal",
            name: "Овсянка",
            foodId: "oats",
            grams: 80,
            tags: ["breakfast"]
        )
        let untaggedRecipe = makeRecipe(
            id: "untagged_oatmeal",
            name: "Овсянка без тега",
            foodId: "oats",
            grams: 80,
            tags: []
        )

        let taggedScore = RecipeScorer.evaluate(
            recipe: taggedRecipe,
            mealType: .breakfast,
            goal: nil,
            foodsById: foodsById,
            nutrientFocus: .none
        )

        let untaggedScore = RecipeScorer.evaluate(
            recipe: untaggedRecipe,
            mealType: .breakfast,
            goal: nil,
            foodsById: foodsById,
            nutrientFocus: .none
        )

        XCTAssertEqual(taggedScore.tagBonus, 8.0, accuracy: 0.01)
        XCTAssertEqual(untaggedScore.tagBonus, 0.0, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(taggedScore.totalScore, untaggedScore.totalScore)
    }

    func testEvaluateAddsIronBonusWhenIronFocusIsSelected() {
        let foodsById = makeFoods()
        let recipe = makeRecipe(
            id: "iron_oatmeal",
            name: "Овсянка",
            foodId: "oats",
            grams: 100,
            tags: ["breakfast"]
        )

        let noFocusScore = RecipeScorer.evaluate(
            recipe: recipe,
            mealType: .breakfast,
            goal: nil,
            foodsById: foodsById,
            nutrientFocus: .none
        )

        let ironFocusScore = RecipeScorer.evaluate(
            recipe: recipe,
            mealType: .breakfast,
            goal: nil,
            foodsById: foodsById,
            nutrientFocus: .iron
        )

        XCTAssertEqual(ironFocusScore.ironAmount, 4.0, accuracy: 0.01)
        XCTAssertGreaterThan(ironFocusScore.nutrientBonus, noFocusScore.nutrientBonus)
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
            cookTimeMinutes: 10,
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
            "chicken": Food(
                id: "chicken",
                name: "Курица",
                macrosPer100g: Macros(calories: 165, protein: 31, fat: 3.6, carbs: 0),
                nutrientsPer100g: [:],
                tags: ["meat", "high_protein"],
                groups: ["poultry"],
                allergens: []
            )
        ]
    }
}
