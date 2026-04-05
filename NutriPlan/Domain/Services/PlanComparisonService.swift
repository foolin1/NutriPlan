import Foundation

enum PlanComparisonService {

    static func compare(
        planned: NutritionSummary,
        actual: NutritionSummary
    ) -> PlanComparison {

        let calories = PlanComparisonMetric(
            title: "Calories",
            unit: "kcal",
            planned: planned.macros.calories,
            actual: actual.macros.calories
        )

        let protein = PlanComparisonMetric(
            title: "Protein",
            unit: "g",
            planned: planned.macros.protein,
            actual: actual.macros.protein
        )

        let fat = PlanComparisonMetric(
            title: "Fat",
            unit: "g",
            planned: planned.macros.fat,
            actual: actual.macros.fat
        )

        let carbs = PlanComparisonMetric(
            title: "Carbs",
            unit: "g",
            planned: planned.macros.carbs,
            actual: actual.macros.carbs
        )

        let plannedIron = planned.nutrients["iron", default: 0]
        let actualIron = actual.nutrients["iron", default: 0]

        let iron: PlanComparisonMetric? =
            (plannedIron > 0 || actualIron > 0)
            ? PlanComparisonMetric(
                title: "Iron",
                unit: "mg",
                planned: plannedIron,
                actual: actualIron
            )
            : nil

        return PlanComparison(
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            iron: iron
        )
    }
}
