import Foundation

struct DayPlan: Codable, Hashable {
    var meals: [PlannedMeal]

    static let empty = DayPlan(meals: [])
}
