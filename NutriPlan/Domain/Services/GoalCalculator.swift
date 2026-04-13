import Foundation

enum GoalCalculator {
    static func calculate(for profile: UserProfile) -> NutritionGoal {
        let ree = restingEnergy(for: profile)
        let tdee = ree * profile.activityLevel.multiplier
        let adjustedCalories = tdee * profile.goalType.calorieAdjustment

        let targetCalories = normalizedCalories(
            adjustedCalories,
            sex: profile.sex,
            goalType: profile.goalType
        )

        var proteinGrams = normalizedProtein(
            weightKg: profile.weightKg,
            multiplier: profile.goalType.proteinMultiplier
        )

        var fatGrams = normalizedFat(
            weightKg: profile.weightKg,
            multiplier: profile.goalType.fatMultiplier
        )

        let minimumCarbGrams = minimumCarbs(for: profile.goalType)
        let minimumCarbCalories = Double(minimumCarbGrams * 4)

        let targetCaloriesDouble = Double(targetCalories)
        var reservedCalories = Double(proteinGrams * 4 + fatGrams * 9)

        if reservedCalories + minimumCarbCalories > targetCaloriesDouble {
            let allowedForProteinAndFat = max(targetCaloriesDouble - minimumCarbCalories, 0)

            if reservedCalories > 0 {
                let reductionFactor = allowedForProteinAndFat / reservedCalories

                proteinGrams = max(
                    minimumProtein(for: profile.goalType),
                    Int((Double(proteinGrams) * reductionFactor).rounded())
                )

                fatGrams = max(
                    minimumFat(for: profile.goalType),
                    Int((Double(fatGrams) * reductionFactor).rounded())
                )
            }

            reservedCalories = Double(proteinGrams * 4 + fatGrams * 9)
        }

        var carbsGrams = Int(((targetCaloriesDouble - reservedCalories) / 4.0).rounded())
        carbsGrams = max(minimumCarbGrams, carbsGrams)

        let finalReservedCalories = Double(proteinGrams * 4 + fatGrams * 9 + carbsGrams * 4)

        if finalReservedCalories > targetCaloriesDouble {
            let extraCalories = finalReservedCalories - targetCaloriesDouble
            let carbReduction = Int((extraCalories / 4.0).rounded())
            carbsGrams = max(minimumCarbGrams, carbsGrams - carbReduction)
        }

        return NutritionGoal(
            targetCalories: targetCalories,
            proteinGrams: proteinGrams,
            fatGrams: fatGrams,
            carbsGrams: carbsGrams
        )
    }

    private static func restingEnergy(for profile: UserProfile) -> Double {
        let weight = profile.weightKg
        let height = profile.heightCm
        let age = Double(profile.age)

        switch profile.sex {
        case .male:
            return 10.0 * weight + 6.25 * height - 5.0 * age + 5.0
        case .female:
            return 10.0 * weight + 6.25 * height - 5.0 * age - 161.0
        }
    }

    private static func normalizedCalories(
        _ rawCalories: Double,
        sex: BiologicalSex,
        goalType: GoalType
    ) -> Int {
        let minimum: Double
        switch (sex, goalType) {
        case (.female, .loseWeight):
            minimum = 1200
        case (.male, .loseWeight):
            minimum = 1400
        case (.female, _):
            minimum = 1400
        case (.male, _):
            minimum = 1600
        }

        let capped = clamp(rawCalories, min: minimum, max: 4200)
        return roundToNearest10(capped)
    }

    private static func normalizedProtein(weightKg: Double, multiplier: Double) -> Int {
        let raw = weightKg * multiplier
        let rounded = Int(raw.rounded())
        return max(60, min(220, rounded))
    }

    private static func normalizedFat(weightKg: Double, multiplier: Double) -> Int {
        let raw = weightKg * multiplier
        let rounded = Int(raw.rounded())
        return max(40, min(120, rounded))
    }

    private static func minimumProtein(for goalType: GoalType) -> Int {
        switch goalType {
        case .loseWeight:
            return 85
        case .maintainWeight:
            return 75
        case .gainWeight:
            return 85
        }
    }

    private static func minimumFat(for goalType: GoalType) -> Int {
        switch goalType {
        case .loseWeight:
            return 40
        case .maintainWeight:
            return 45
        case .gainWeight:
            return 50
        }
    }

    private static func minimumCarbs(for goalType: GoalType) -> Int {
        switch goalType {
        case .loseWeight:
            return 90
        case .maintainWeight:
            return 120
        case .gainWeight:
            return 150
        }
    }

    private static func roundToNearest10(_ value: Double) -> Int {
        Int((value / 10.0).rounded() * 10.0)
    }

    private static func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}
