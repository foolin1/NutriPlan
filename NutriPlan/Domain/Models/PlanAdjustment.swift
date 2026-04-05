import Foundation

struct PlanAdjustment: Hashable {
    let statusTitle: String
    let summary: String
    let nextDayGoal: NutritionGoal
    let hints: [String]
}
