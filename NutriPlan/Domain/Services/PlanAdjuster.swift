import Foundation

enum PlanAdjuster {
    static func recommend(
        baseGoal: NutritionGoal,
        actual: NutritionSummary
    ) -> PlanAdjustment {
        let actualCalories = actual.macros.calories
        let actualProtein = actual.macros.protein
        let actualFat = actual.macros.fat
        let actualCarbs = actual.macros.carbs

        let calorieDelta = actualCalories - Double(baseGoal.targetCalories)
        let proteinDelta = actualProtein - Double(baseGoal.proteinGrams)
        let fatDelta = actualFat - Double(baseGoal.fatGrams)
        let carbsDelta = actualCarbs - Double(baseGoal.carbsGrams)

        let calorieCorrection = clamp(calorieDelta * 0.35, min: -180, max: 180)
        let nextCalories = max(
            1200,
            Int((Double(baseGoal.targetCalories) - calorieCorrection).rounded())
        )

        var nextProtein = baseGoal.proteinGrams
        var nextFat = baseGoal.fatGrams

        if proteinDelta < -10 {
            nextProtein += Int(min(20, abs(proteinDelta) * 0.5).rounded())
        }

        if fatDelta > 12 {
            nextFat = max(
                35,
                baseGoal.fatGrams - Int(min(10, (fatDelta - 12) * 0.3).rounded())
            )
        } else if fatDelta < -10 {
            nextFat += Int(min(8, abs(fatDelta) * 0.2).rounded())
        }

        let proteinCalories = Double(nextProtein * 4)
        let fatCalories = Double(nextFat * 9)
        let remainingForCarbs = max(Double(nextCalories) - proteinCalories - fatCalories, 0)
        let nextCarbs = Int((remainingForCarbs / 4.0).rounded())

        let nextGoal = NutritionGoal(
            targetCalories: nextCalories,
            proteinGrams: nextProtein,
            fatGrams: nextFat,
            carbsGrams: nextCarbs
        )

        let statusTitle: String
        if abs(calorieDelta) <= 120 && abs(proteinDelta) <= 10 {
            statusTitle = "Ты близок к целевым значениям"
        } else if calorieDelta > 120 {
            statusTitle = "Завтра стоит немного снизить калорийность"
        } else if calorieDelta < -120 {
            statusTitle = "Завтра стоит немного повысить калорийность"
        } else {
            statusTitle = "На завтра можно слегка скорректировать цель"
        }

        let summary = """
        Цель на завтра была мягко скорректирована с \(baseGoal.targetCalories) ккал до \(nextGoal.targetCalories) ккал, чтобы сохранить сбалансированный рацион без слишком резкой компенсации.
        """

        var hints: [String] = []

        if calorieDelta > 150 {
            hints.append("Немного снизить калорийность завтра будет полезнее, чем делать резкое ограничение.")
        } else if calorieDelta < -150 {
            hints.append("Стоит немного повысить калорийность завтра, чтобы рацион оставался устойчивым.")
        }

        if proteinDelta < -10 {
            hints.append("Завтра лучше немного увеличить белок для сытости и восстановления.")
        }

        if fatDelta > 12 {
            hints.append("Жиры завтра можно немного уменьшить и сместить акцент в сторону нежирного белка и сложных углеводов.")
        }

        if carbsDelta > 25 {
            hints.append("Плотные углеводные порции завтра можно немного сократить.")
        } else if carbsDelta < -25 {
            hints.append("Завтра можно добавить немного больше сложных углеводов для энергии.")
        }

        if hints.isEmpty {
            hints.append("Можно сохранить текущую структуру питания и придерживаться похожих целей завтра.")
        }

        return PlanAdjustment(
            statusTitle: statusTitle,
            summary: summary,
            nextDayGoal: nextGoal,
            hints: hints
        )
    }

    private static func clamp(
        _ value: Double,
        min minValue: Double,
        max maxValue: Double
    ) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}
