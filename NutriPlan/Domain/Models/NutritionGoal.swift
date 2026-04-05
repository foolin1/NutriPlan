import Foundation

struct NutritionGoal: Codable, Hashable {
    let targetCalories: Int
    let proteinGrams: Int
    let fatGrams: Int
    let carbsGrams: Int
}
