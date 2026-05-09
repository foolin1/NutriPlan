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

        let calorieCorrectionResult = adaptiveCalorieCorrection(
            delta: calorieDelta,
            baseCalories: baseGoal.targetCalories
        )

        let rawNextCalories = Double(baseGoal.targetCalories) - calorieCorrectionResult.value
        let boundedNextCalories = clamp(
            rawNextCalories,
            min: 1200,
            max: Double(baseGoal.targetCalories) + calorieCorrectionResult.maxShift
        )
        let nextCalories = roundToNearest10(boundedNextCalories)

        var nextProtein = baseGoal.proteinGrams
        var nextFat = baseGoal.fatGrams

        if proteinDelta < -12 {
            nextProtein += Int(min(18, abs(proteinDelta) * 0.45).rounded())
        } else if proteinDelta > 25 {
            nextProtein = max(
                70,
                baseGoal.proteinGrams - Int(min(10, (proteinDelta - 25) * 0.15).rounded())
            )
        }

        if fatDelta > 12 {
            nextFat = max(
                35,
                baseGoal.fatGrams - Int(min(10, (fatDelta - 12) * 0.30).rounded())
            )
        } else if fatDelta < -12 {
            nextFat += Int(min(8, abs(fatDelta) * 0.20).rounded())
        }

        let proteinCalories = Double(nextProtein * 4)
        let fatCalories = Double(nextFat * 9)
        let minimumCarbs = 90
        let remainingForCarbs = max(
            Double(nextCalories) - proteinCalories - fatCalories,
            Double(minimumCarbs * 4)
        )
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
            calorieDelta: calorieDelta,
            correction: calorieCorrectionResult
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
        if abs(calorieDelta) <= 100 && abs(proteinDelta) <= 10 && abs(fatDelta) <= 10 {
            return "План выполнен близко к цели"
        }

        if calorieDelta > 100 {
            return "На завтра стоит снизить калорийность"
        }

        if calorieDelta < -100 {
            return "На завтра стоит повысить калорийность"
        }

        return "На завтра предлагается небольшая корректировка"
    }

    private static func makeSummary(
        baseGoal: NutritionGoal,
        nextGoal: NutritionGoal,
        calorieDelta: Double,
        correction: CalorieCorrectionResult
    ) -> String {
        let roundedDelta = Int(calorieDelta.rounded())
        let roundedCorrection = Int(correction.value.rounded())

        if correction.rate == 0 {
            return """
            Отклонение от плана составило \(formatSigned(roundedDelta)) ккал. \
            Оно находится в допустимом диапазоне, поэтому целевая калорийность на следующий день сохранена: \
            \(baseGoal.targetCalories) ккал.
            """
        }

        let compensationPercent = Int((correction.rate * 100).rounded())
        let direction: String

        if calorieDelta > 0 {
            direction = "Фактическая калорийность была выше плана"
        } else {
            direction = "Фактическая калорийность была ниже плана"
        }

        return """
        \(direction) на \(abs(roundedDelta)) ккал. \
        На следующий день компенсируется \(compensationPercent)% отклонения, \
        что дает поправку \(abs(roundedCorrection)) ккал. \
        Целевая калорийность изменена: \(baseGoal.targetCalories) → \(nextGoal.targetCalories) ккал.
        """
    }

    private static func makeHints(
        calorieDelta: Double,
        proteinDelta: Double,
        fatDelta: Double,
        carbsDelta: Double
    ) -> [String] {
        var hints: [String] = []

        if calorieDelta > 100 {
            hints.append("Завтра лучше немного сократить общую калорийность, но не пытаться компенсировать всё отклонение за один день.")
        } else if calorieDelta < -100 {
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

    private static func adaptiveCalorieCorrection(
        delta: Double,
        baseCalories: Int
    ) -> CalorieCorrectionResult {
        let absDelta = abs(delta)
        let maxShift = dynamicCalorieShiftLimit(baseCalories: baseCalories)

        guard absDelta > 100 else {
            return CalorieCorrectionResult(
                value: 0,
                rate: 0,
                maxShift: maxShift
            )
        }

        let rate = compensationRate(forAbsoluteDelta: absDelta)
        let rawCorrection = delta * rate
        let boundedCorrection = clamp(
            rawCorrection,
            min: -maxShift,
            max: maxShift
        )

        return CalorieCorrectionResult(
            value: boundedCorrection,
            rate: rate,
            maxShift: maxShift
        )
    }

    private static func compensationRate(forAbsoluteDelta absDelta: Double) -> Double {
        switch absDelta {
        case 0...100:
            return 0
        case 100...300:
            return 0.25
        case 300...700:
            return 0.40
        default:
            return 0.50
        }
    }

    private static func dynamicCalorieShiftLimit(baseCalories: Int) -> Double {
        min(
            350.0,
            max(180.0, Double(baseCalories) * 0.15)
        )
    }

    private static func roundToNearest10(_ value: Double) -> Int {
        Int((value / 10.0).rounded() * 10.0)
    }

    private static func clamp(
        _ value: Double,
        min minValue: Double,
        max maxValue: Double
    ) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value))
    }

    private static func formatSigned(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }

    private struct CalorieCorrectionResult {
        let value: Double
        let rate: Double
        let maxShift: Double
    }
}
