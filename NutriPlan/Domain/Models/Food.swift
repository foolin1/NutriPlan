import Foundation

/// Продукт (значения обычно задаём "на 100г")
struct Food: Identifiable, Codable, Hashable {
    let id: String
    let name: String

    /// Макросы на 100г
    let macrosPer100g: Macros

    /// Микронутриенты на 100г: [nutrientId: amount]
    let nutrientsPer100g: [String: Double]

    /// Метки (под замены/фильтры): "dairy", "meat", "vegan", "nuts" и т.п.
    let tags: Set<String>

    /// Аллергены (для фильтра): "lactose", "nuts", "gluten" и т.п.
    let allergens: Set<String>

    init(
        id: String,
        name: String,
        macrosPer100g: Macros,
        nutrientsPer100g: [String: Double] = [:],
        tags: Set<String> = [],
        allergens: Set<String> = []
    ) {
        self.id = id
        self.name = name
        self.macrosPer100g = macrosPer100g
        self.nutrientsPer100g = nutrientsPer100g
        self.tags = tags
        self.allergens = allergens
    }
}
