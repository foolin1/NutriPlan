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

        let calorieCorrection = clamp(calorieDelta * 0.30, min: -180, max: 180)

        let rawNextCalories = Double(baseGoal.targetCalories) - calorieCorrection
        let boundedNextCalories = clamp(
            rawNextCalories,
            min: max(1200, Double(baseGoal.targetCalories - 220)),
            max: Double(baseGoal.targetCalories + 220)
        )
        let nextCalories = roundToNearest10(boundedNextCalories)

        var nextProtein = baseGoal.proteinGrams
        var nextFat = baseGoal.fatGrams

        if proteinDelta < -12 {
            nextProtein += Int(min(18, abs(proteinDelta) * 0.45).rounded())
        } else if proteinDelta > 25 {
            nextProtein = max(70, baseGoal.proteinGrams - Int(min(10, (proteinDelta - 25) * 0.15).rounded()))
        }

        if fatDelta > 12 {
            nextFat = max(35, baseGoal.fatGrams - Int(min(10, (fatDelta - 12) * 0.30).rounded()))
        } else if fatDelta < -12 {
            nextFat += Int(min(8, abs(fatDelta) * 0.20).rounded())
        }

        let proteinCalories = Double(nextProtein * 4)
        let fatCalories = Double(nextFat * 9)
        let minimumCarbs = 90
        let remainingForCarbs = max(Double(nextCalories) - proteinCalories - fatCalories, Double(minimumCarbs * 4))
        let nextCarbs = max(minimumCarbs, Int((remainingForCarbs / 4.0).rounded()))

        let nextGoal = NutritionGoal(
            targetCalories: nextCalories,
            proteinGrams: nextProtein,
            fatGrams: nextFat,
            carbsGrams: nextCarbs
        )

        let statusTitle = makeStatusTitle(
            calorieDelta: calorieDelta,
            proteinDelta: proteinDelta,
            fatDelta: fatDelta
        )

        let summary = makeSummary(
            baseGoal: baseGoal,
            nextGoal: nextGoal,
            calorieDelta: calorieDelta
        )

        let hints = makeHints(
            calorieDelta: calorieDelta,
            proteinDelta: proteinDelta,
            fatDelta: fatDelta,
            carbsDelta: carbsDelta
        )

        return PlanAdjustment(
            statusTitle: statusTitle,
            summary: summary,
            nextDayGoal: nextGoal,
            hints: hints
        )
    }

    private static func makeStatusTitle(
        calorieDelta: Double,
        proteinDelta: Double,
        fatDelta: Double
    ) -> String {
        if abs(calorieDelta) <= 120 && abs(proteinDelta) <= 10 && abs(fatDelta) <= 10 {
            return "План выполнен близко к цели"
        }

        if calorieDelta > 120 {
            return "На завтра стоит немного снизить калорийность"
        }

        if calorieDelta < -120 {
            return "На завтра стоит немного повысить калорийность"
        }

        return "На завтра предлагается небольшая корректировка"
    }

    private static func makeSummary(
        baseGoal: NutritionGoal,
        nextGoal: NutritionGoal,
        calorieDelta: Double
    ) -> String {
        let direction: String
        if calorieDelta > 120 {
            direction = "После небольшого избытка"
        } else if calorieDelta < -120 {
            direction = "После недобора"
        } else {
            direction = "После небольшого отклонения"
        }

        return "\(direction) цель на следующий день мягко скорректирована: \(baseGoal.targetCalories) → \(nextGoal.targetCalories) ккал. Коррекция сделана без резких ограничений, чтобы сохранить устойчивость рациона."
    }

    private static func makeHints(
        calorieDelta: Double,
        proteinDelta: Double,
        fatDelta: Double,
        carbsDelta: Double
    ) -> [String] {
        var hints: [String] = []

        if calorieDelta > 150 {
            hints.append("Завтра лучше немного сократить общую калорийность, а не пытаться компенсировать всё сразу.")
        } else if calorieDelta < -150 {
            hints.append("Завтра лучше немного добрать калории, чтобы рацион оставался комфортным и стабильным.")
        }

        if proteinDelta < -12 {
            hints.append("Стоит добавить чуть больше белка: нежирное мясо, яйца, рыбу, творог или бобовые.")
        } else if proteinDelta > 25 {
            hints.append("Белка было с запасом, поэтому завтра можно оставить порции без дополнительного увеличения.")
        }

        if fatDelta > 12 {
            hints.append("Жиры были выше цели — завтра лучше сместить акцент в сторону более постных продуктов.")
        } else if fatDelta < -12 {
            hints.append("Жиров было маловато — завтра можно добавить немного источников полезных жиров.")
        }

        if carbsDelta > 25 {
            hints.append("Плотные углеводные порции завтра лучше сделать чуть меньше.")
        } else if carbsDelta < -25 {
            hints.append("Завтра можно немного увеличить долю сложных углеводов для лучшего баланса энергии.")
        }

        if hints.isEmpty {
            hints.append("Существенных отклонений нет — можно сохранить ту же структуру плана на следующий день.")
        }

        return hints
    }

    private static func roundToNearest10(_ value: Double) -> Int {
        Int((value / 10.0).rounded() * 10.0)
    }

    private static func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}
