import Foundation

/// Итог по макросам и микроэлементам
struct NutritionSummary: Codable, Hashable {
    var macros: Macros
    var nutrients: [String: Double]   // [nutrientId: amount]

    static let zero = NutritionSummary(macros: .zero, nutrients: [:])
}

enum NutritionCalculator {

    /// Считает итог по ингредиентам, зная справочник продуктов.
    /// - foodsById: словарь продуктов, где ключ = Food.id
    static func summarize(
        ingredients: [RecipeIngredient],
        foodsById: [String: Food]
    ) -> NutritionSummary {

        var totalMacros = Macros.zero
        var totalNutrients: [String: Double] = [:]

        for ing in ingredients {
            guard let food = foodsById[ing.foodId] else { continue }

            let factor = ing.grams / 100.0   // т.к. значения на 100г
            totalMacros = totalMacros + (food.macrosPer100g * factor)

            for (nutrientId, amountPer100g) in food.nutrientsPer100g {
                totalNutrients[nutrientId, default: 0] += amountPer100g * factor
            }
        }

        return NutritionSummary(macros: totalMacros, nutrients: totalNutrients)
    }
}
