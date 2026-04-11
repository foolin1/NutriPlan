import Foundation
import Testing
@testable import NutriPlan

struct GoalCalculatorTests {
    @Test("Расчёт цели для мужчины с поддержанием веса даёт ожидаемые значения")
    func maleMaintainGoal() {
        let profile = UserProfile(
            sex: .male,
            age: 30,
            heightCm: 180,
            weightKg: 80,
            activityLevel: .moderate,
            goalType: .maintainWeight
        )

        let goal = GoalCalculator.calculate(for: profile)

        #expect(goal.targetCalories == 2759)
        #expect(goal.proteinGrams == 128)
        #expect(goal.fatGrams == 72)
        #expect(goal.carbsGrams == 400)
    }

    @Test("Снижение веса даёт меньшую калорийность, чем поддержание, а набор — большую")
    func calorieAdjustmentsByGoalType() {
        let baseProfile = UserProfile(
            sex: .female,
            age: 28,
            heightCm: 168,
            weightKg: 65,
            activityLevel: .moderate,
            goalType: .maintainWeight
        )

        let loseGoal = GoalCalculator.calculate(
            for: UserProfile(
                sex: baseProfile.sex,
                age: baseProfile.age,
                heightCm: baseProfile.heightCm,
                weightKg: baseProfile.weightKg,
                activityLevel: baseProfile.activityLevel,
                goalType: .loseWeight
            )
        )

        let maintainGoal = GoalCalculator.calculate(for: baseProfile)

        let gainGoal = GoalCalculator.calculate(
            for: UserProfile(
                sex: baseProfile.sex,
                age: baseProfile.age,
                heightCm: baseProfile.heightCm,
                weightKg: baseProfile.weightKg,
                activityLevel: baseProfile.activityLevel,
                goalType: .gainWeight
            )
        )

        #expect(loseGoal.targetCalories < maintainGoal.targetCalories)
        #expect(gainGoal.targetCalories > maintainGoal.targetCalories)
    }
}
