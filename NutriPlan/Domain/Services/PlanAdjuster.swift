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

        // Мягкая корректировка: не переносим весь "долг" или "избыток" на завтра,
        // а компенсируем только часть.
        let calorieCorrection = clamp(calorieDelta * 0.35, min: -180, max: 180)
        let nextCalories = max(1200, Int((Double(baseGoal.targetCalories) - calorieCorrection).rounded()))

        var nextProtein = baseGoal.proteinGrams
        var nextFat = baseGoal.fatGrams

        // Если белка заметно не хватило — чуть повышаем цель по белку на завтра
        if proteinDelta < -10 {
            nextProtein += Int(min(20, abs(proteinDelta) * 0.5).rounded())
        }

        // Если жиров было заметно больше — немного снижаем жиры на завтра
        if fatDelta > 12 {
            nextFat = max(35, baseGoal.fatGrams - Int(min(10, (fatDelta - 12) * 0.3).rounded()))
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
            statusTitle = "You are close to the target"
        } else if calorieDelta > 120 {
            statusTitle = "Light calorie reduction for tomorrow"
        } else if calorieDelta < -120 {
            statusTitle = "Slight increase for tomorrow"
        } else {
            statusTitle = "Small adjustment for tomorrow"
        }

        let summary = """
        Tomorrow’s target is softly adjusted from \(baseGoal.targetCalories) kcal to \(nextGoal.targetCalories) kcal, \
        while keeping the plan balanced and avoiding harsh compensation.
        """

        var hints: [String] = []

        if calorieDelta > 150 {
            hints.append("Reduce total calories slightly tomorrow instead of making a sharp cut.")
        } else if calorieDelta < -150 {
            hints.append("Increase calories a little tomorrow so the plan stays sustainable.")
        }

        if proteinDelta < -10 {
            hints.append("Increase protein tomorrow to better support satiety and recovery.")
        }

        if fatDelta > 12 {
            hints.append("Keep fats a little lower tomorrow and shift calories toward lean protein or complex carbs.")
        }

        if carbsDelta > 25 {
            hints.append("Slightly reduce dense carb portions tomorrow.")
        } else if carbsDelta < -25 {
            hints.append("Add a bit more carbohydrate-rich food tomorrow for energy balance.")
        }

        if hints.isEmpty {
            hints.append("Keep the current structure of the plan and follow the same targets tomorrow.")
        }

        return PlanAdjustment(
            statusTitle: statusTitle,
            summary: summary,
            nextDayGoal: nextGoal,
            hints: hints
        )
    }

    private static func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}
