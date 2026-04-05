import Foundation

struct RecipeIngredient: Codable, Hashable {
    let foodId: String
    let grams: Double
}

struct Recipe: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    var ingredients: [RecipeIngredient]

    var cookTimeMinutes: Int?
    var tags: Set<String> = []

    // Нужно, чтобы понимать: показывать базовое имя или динамическое
    var isModified: Bool = false
}
