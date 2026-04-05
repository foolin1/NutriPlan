import Foundation

struct ConsumedFoodEntry: Identifiable, Codable, Hashable {
    var id: UUID
    let mealId: UUID?
    let mealType: MealType
    var title: String
    var recipe: Recipe
    let loggedAt: Date

    init(
        id: UUID = UUID(),
        mealId: UUID?,
        mealType: MealType,
        title: String,
        recipe: Recipe,
        loggedAt: Date = Date()
    ) {
        self.id = id
        self.mealId = mealId
        self.mealType = mealType
        self.title = title
        self.recipe = recipe
        self.loggedAt = loggedAt
    }
}
