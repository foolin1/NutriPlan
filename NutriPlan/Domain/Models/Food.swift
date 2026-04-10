import Foundation

/// Продукт (значения обычно задаём "на 100г")
struct Food: Identifiable, Codable, Hashable {
    let id: String
    let name: String

    /// Макросы на 100г
    let macrosPer100g: Macros

    /// Микронутриенты на 100г: [nutrientId: amount]
    let nutrientsPer100g: [String: Double]

    /// Теги для логики ранжирования и замен
    let tags: Set<String>

    /// Внутренние группы для ограничений:
    /// citrus, berries, dairy, nuts, legumes, seafood, eggs, poultry и т.д.
    let groups: Set<String>

    /// Аллергены
    let allergens: Set<String>

    init(
        id: String,
        name: String,
        macrosPer100g: Macros,
        nutrientsPer100g: [String: Double] = [:],
        tags: Set<String> = [],
        groups: Set<String> = [],
        allergens: Set<String> = []
    ) {
        self.id = id
        self.name = name
        self.macrosPer100g = macrosPer100g
        self.nutrientsPer100g = nutrientsPer100g
        self.tags = tags
        self.groups = groups
        self.allergens = allergens
    }
}
