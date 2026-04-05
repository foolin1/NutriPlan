import Foundation

enum ShoppingListBuilder {

    static func build(
        recipes: [Recipe],
        foodsById: [String: Food]
    ) -> [ShoppingItem] {

        var totals: [String: Double] = [:] // foodId -> grams

        for recipe in recipes {
            for ing in recipe.ingredients {
                totals[ing.foodId, default: 0] += ing.grams
            }
        }

        let items: [ShoppingItem] = totals.compactMap { (foodId, grams) in
            guard let food = foodsById[foodId] else { return nil }
            return ShoppingItem(
                id: foodId,
                name: food.name,
                grams: grams,
                categoryKey: categoryKey(for: food)
            )
        }

        return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func categoryKey(for food: Food) -> String {
        // приоритет категорий — можно расширять
        if food.tags.contains("meat") { return "category.meat" }
        if food.tags.contains("grain") { return "category.grain" }
        if food.tags.contains("vegetable") { return "category.vegetable" }
        return "category.other"
    }
}
