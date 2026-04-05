import Foundation

struct PlanComparisonMetric: Hashable {
    let title: String
    let unit: String
    let planned: Double
    let actual: Double

    var delta: Double {
        actual - planned
    }

    var completionPercent: Double {
        guard planned > 0 else { return 0 }
        return (actual / planned) * 100
    }
}

struct PlanComparison: Hashable {
    let calories: PlanComparisonMetric
    let protein: PlanComparisonMetric
    let fat: PlanComparisonMetric
    let carbs: PlanComparisonMetric
    let iron: PlanComparisonMetric?
}
