import Foundation

enum GoalCalculator {

    static func calculate(for profile: UserProfile) -> NutritionGoal {
        let bmr = basalMetabolicRate(for: profile)
        let maintenanceCalories = bmr * profile.activityLevel.multiplier
        let targetCalories = maintenanceCalories * profile.goalType.calorieAdjustment

        let protein = profile.weightKg * profile.goalType.proteinMultiplier
        let fat = profile.weightKg * profile.goalType.fatMultiplier

        let remainingCaloriesForCarbs = max(targetCalories - protein * 4.0 - fat * 9.0, 0)
        let carbs = remainingCaloriesForCarbs / 4.0

        return NutritionGoal(
            targetCalories: Int(targetCalories.rounded()),
            proteinGrams: Int(protein.rounded()),
            fatGrams: Int(fat.rounded()),
            carbsGrams: Int(carbs.rounded())
        )
    }

    private static func basalMetabolicRate(for profile: UserProfile) -> Double {
        switch profile.sex {
        case .male:
            return 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * Double(profile.age) + 5
        case .female:
            return 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * Double(profile.age) - 161
        }
    }
}
