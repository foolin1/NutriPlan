import Foundation
import Testing
@testable import NutriPlan

enum TestDataFactory {
    static let chicken = Food(
        id: "chicken_breast",
        name: "Куриная грудка",
        macrosPer100g: Macros(calories: 165, protein: 31.0, fat: 3.6, carbs: 0.0),
        nutrientsPer100g: ["iron": 1.0],
        tags: ["meat"],
        groups: ["poultry"]
    )

    static let turkey = Food(
        id: "turkey_breast",
        name: "Грудка индейки",
        macrosPer100g: Macros(calories: 135, protein: 29.0, fat: 1.6, carbs: 0.0),
        nutrientsPer100g: ["iron": 1.2],
        tags: ["meat"],
        groups: ["poultry"]
    )

    static let beef = Food(
        id: "lean_beef",
        name: "Говядина постная",
        macrosPer100g: Macros(calories: 187, protein: 26.0, fat: 9.0, carbs: 0.0),
        nutrientsPer100g: ["iron": 2.6],
        tags: ["meat"],
        groups: ["red_meat"]
    )

    static let rice = Food(
        id: "rice",
        name: "Рис",
        macrosPer100g: Macros(calories: 130, protein: 2.7, fat: 0.3, carbs: 28.0),
        nutrientsPer100g: [:],
        tags: ["grain"],
        groups: ["grain"]
    )

    static let oats = Food(
        id: "oats",
        name: "Овсяные хлопья",
        macrosPer100g: Macros(calories: 389, protein: 16.9, fat: 6.9, carbs: 66.3),
        nutrientsPer100g: ["iron": 4.7],
        tags: ["grain"],
        groups: ["grain"],
        allergens: ["gluten"]
    )

    static let milk = Food(
        id: "milk",
        name: "Молоко",
        macrosPer100g: Macros(calories: 60, protein: 3.2, fat: 3.3, carbs: 4.8),
        nutrientsPer100g: ["calcium": 120.0],
        tags: ["dairy"],
        groups: ["dairy"],
        allergens: ["lactose"]
    )

    static let yogurt = Food(
        id: "greek_yogurt",
        name: "Греческий йогурт",
        macrosPer100g: Macros(calories: 73, protein: 10.0, fat: 2.0, carbs: 3.9),
        nutrientsPer100g: ["iron": 0.1, "calcium": 110.0],
        tags: ["dairy"],
        groups: ["dairy"],
        allergens: ["lactose"]
    )

    static let cottage = Food(
        id: "cottage_cheese",
        name: "Творог",
        macrosPer100g: Macros(calories: 98, protein: 11.0, fat: 4.3, carbs: 3.4),
        nutrientsPer100g: ["calcium": 83.0],
        tags: ["dairy"],
        groups: ["dairy"],
        allergens: ["lactose"]
    )

    static let banana = Food(
        id: "banana",
        name: "Банан",
        macrosPer100g: Macros(calories: 89, protein: 1.1, fat: 0.3, carbs: 22.8),
        nutrientsPer100g: ["vitamin_c": 8.7],
        tags: ["fruit"],
        groups: ["fruit"]
    )

    static let apple = Food(
        id: "apple",
        name: "Яблоко",
        macrosPer100g: Macros(calories: 52, protein: 0.3, fat: 0.2, carbs: 14.0),
        nutrientsPer100g: ["vitamin_c": 4.6],
        tags: ["fruit"],
        groups: ["fruit"]
    )

    static let orange = Food(
        id: "orange",
        name: "Апельсин",
        macrosPer100g: Macros(calories: 47, protein: 0.9, fat: 0.1, carbs: 11.8),
        nutrientsPer100g: ["vitamin_c": 53.2],
        tags: ["fruit", "citrus"],
        groups: ["fruit", "citrus"]
    )

    static let broccoli = Food(
        id: "broccoli",
        name: "Брокколи",
        macrosPer100g: Macros(calories: 34, protein: 2.8, fat: 0.4, carbs: 6.6),
        nutrientsPer100g: ["vitamin_c": 89.0],
        tags: ["vegetable"],
        groups: ["vegetable"]
    )

    static let chia = Food(
        id: "chia_seeds",
        name: "Семена чиа",
        macrosPer100g: Macros(calories: 486, protein: 16.5, fat: 30.7, carbs: 42.1),
        nutrientsPer100g: ["iron": 7.7],
        tags: ["seed"],
        groups: ["seeds"]
    )

    static let peanutButter = Food(
        id: "peanut_butter",
        name: "Арахисовая паста",
        macrosPer100g: Macros(calories: 588, protein: 25.0, fat: 50.0, carbs: 20.0),
        nutrientsPer100g: ["iron": 1.9],
        tags: ["nut"],
        groups: ["nuts"],
        allergens: ["nuts"]
    )

    static let oliveOil = Food(
        id: "olive_oil",
        name: "Оливковое масло",
        macrosPer100g: Macros(calories: 884, protein: 0.0, fat: 100.0, carbs: 0.0),
        nutrientsPer100g: [:],
        tags: ["fat"],
        groups: ["oil"]
    )

    static var foods: [Food] {
        [
            chicken, turkey, beef,
            rice, oats,
            milk, yogurt, cottage,
            banana, apple, orange,
            broccoli, chia, peanutButter, oliveOil
        ]
    }

    static var foodsById: [String: Food] {
        Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })
    }

    static let breakfast = Recipe(
        id: "breakfast_oats",
        name: "Овсянка с бананом",
        ingredients: [
            RecipeIngredient(foodId: "oats", grams: 60),
            RecipeIngredient(foodId: "milk", grams: 200),
            RecipeIngredient(foodId: "banana", grams: 100),
            RecipeIngredient(foodId: "peanut_butter", grams: 20)
        ],
        cookTimeMinutes: 10,
        tags: ["breakfast", "bowl"],
        isModified: false
    )

    static let lunch = Recipe(
        id: "lunch_chicken_rice",
        name: "Курица с рисом",
        ingredients: [
            RecipeIngredient(foodId: "chicken_breast", grams: 220),
            RecipeIngredient(foodId: "rice", grams: 250),
            RecipeIngredient(foodId: "broccoli", grams: 100),
            RecipeIngredient(foodId: "olive_oil", grams: 10)
        ],
        cookTimeMinutes: 25,
        tags: ["lunch", "plate", "high_protein"],
        isModified: false
    )

    static let dinner = Recipe(
        id: "dinner_turkey_rice",
        name: "Индейка с рисом",
        ingredients: [
            RecipeIngredient(foodId: "turkey_breast", grams: 220),
            RecipeIngredient(foodId: "rice", grams: 250),
            RecipeIngredient(foodId: "broccoli", grams: 100),
            RecipeIngredient(foodId: "olive_oil", grams: 10)
        ],
        cookTimeMinutes: 25,
        tags: ["dinner", "plate", "high_protein"],
        isModified: false
    )

    static let snack1 = Recipe(
        id: "snack_yogurt_chia",
        name: "Йогурт с семенами чиа",
        ingredients: [
            RecipeIngredient(foodId: "greek_yogurt", grams: 180),
            RecipeIngredient(foodId: "chia_seeds", grams: 12),
            RecipeIngredient(foodId: "banana", grams: 60)
        ],
        cookTimeMinutes: 3,
        tags: ["snack", "bowl"],
        isModified: false
    )

    static let snack2 = Recipe(
        id: "snack_cottage_banana",
        name: "Творог с бананом",
        ingredients: [
            RecipeIngredient(foodId: "cottage_cheese", grams: 180),
            RecipeIngredient(foodId: "banana", grams: 100)
        ],
        cookTimeMinutes: 3,
        tags: ["snack", "bowl", "high_protein"],
        isModified: false
    )

    static let citrusSnack = Recipe(
        id: "snack_orange_yogurt",
        name: "Апельсин с йогуртом",
        ingredients: [
            RecipeIngredient(foodId: "orange", grams: 150),
            RecipeIngredient(foodId: "greek_yogurt", grams: 160)
        ],
        cookTimeMinutes: 3,
        tags: ["snack", "bowl"],
        isModified: false
    )

    static var highCalorieRecipes: [Recipe] {
        [breakfast, lunch, dinner, snack1, snack2, citrusSnack]
    }

    static let highGoal = NutritionGoal(
        targetCalories: 2500,
        proteinGrams: 180,
        fatGrams: 80,
        carbsGrams: 250
    )

    static func summary(for plan: DayPlan) -> NutritionSummary {
        var totalMacros = Macros.zero
        var totalNutrients: [String: Double] = [:]

        for meal in plan.meals {
            let summary = NutritionCalculator.summarize(
                ingredients: meal.recipe.ingredients,
                foodsById: foodsById
            )

            totalMacros = totalMacros + summary.macros

            for (key, value) in summary.nutrients {
                totalNutrients[key, default: 0] += value
            }
        }

        return NutritionSummary(macros: totalMacros, nutrients: totalNutrients)
    }
}

final class TestSessionStore: PlanSessionStore {
    private var stored: PersistedPlanSession?

    func load() -> PersistedPlanSession? {
        stored
    }

    func save(
        inputSignature: PlanInputSignature,
        dayPlan: DayPlan,
        diaryDay: DiaryDay
    ) {
        stored = PersistedPlanSession(
            inputSignature: inputSignature,
            dayPlan: dayPlan,
            diaryDay: diaryDay
        )
    }

    func clear() {
        stored = nil
    }
}
