import Foundation

struct PlannedMeal: Identifiable, Codable, Hashable {
    let id: UUID
    let type: MealType
    var recipe: Recipe

    init(id: UUID = UUID(), type: MealType, recipe: Recipe) {
        self.id = id
        self.type = type
        self.recipe = recipe
    }
}
