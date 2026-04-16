import XCTest
@testable import NutriPlan

final class GoalCalculatorTests: XCTestCase {

    func testLoseWeightProducesLowerCaloriesThanMaintainForSameProfile() {
        let maintainProfile = makeProfile(goalType: .maintainWeight)
        let loseProfile = makeProfile(goalType: .loseWeight)

        let maintainGoal = GoalCalculator.calculate(for: maintainProfile)
        let loseGoal = GoalCalculator.calculate(for: loseProfile)

        XCTAssertLessThan(loseGoal.targetCalories, maintainGoal.targetCalories)
    }

    func testGainWeightProducesHigherCaloriesThanMaintainForSameProfile() {
        let maintainProfile = makeProfile(goalType: .maintainWeight)
        let gainProfile = makeProfile(goalType: .gainWeight)

        let maintainGoal = GoalCalculator.calculate(for: maintainProfile)
        let gainGoal = GoalCalculator.calculate(for: gainProfile)

        XCTAssertGreaterThan(gainGoal.targetCalories, maintainGoal.targetCalories)
    }

    func testMaleLoseWeightRespectsMinimumCaloriesFloor() {
        let profile = UserProfile(
            sex: .male,
            age: 35,
            heightCm: 170,
            weightKg: 52,
            activityLevel: .low,
            goalType: .loseWeight,
            nutrientFocus: .none,
            excludedAllergens: [],
            excludedProducts: [],
            excludedGroups: []
        )

        let goal = GoalCalculator.calculate(for: profile)

        XCTAssertGreaterThanOrEqual(goal.targetCalories, 1400)
    }

    func testFemaleLoseWeightRespectsMinimumCaloriesFloor() {
        let profile = UserProfile(
            sex: .female,
            age: 35,
            heightCm: 160,
            weightKg: 45,
            activityLevel: .low,
            goalType: .loseWeight,
            nutrientFocus: .none,
            excludedAllergens: [],
            excludedProducts: [],
            excludedGroups: []
        )

        let goal = GoalCalculator.calculate(for: profile)

        XCTAssertGreaterThanOrEqual(goal.targetCalories, 1200)
    }

    func testCalculatedMacrosArePositive() {
        let profile = makeProfile(goalType: .maintainWeight)

        let goal = GoalCalculator.calculate(for: profile)

        XCTAssertGreaterThan(goal.proteinGrams, 0)
        XCTAssertGreaterThan(goal.fatGrams, 0)
        XCTAssertGreaterThan(goal.carbsGrams, 0)
        XCTAssertGreaterThan(goal.targetCalories, 0)
    }

    private func makeProfile(goalType: GoalType) -> UserProfile {
        UserProfile(
            sex: .male,
            age: 28,
            heightCm: 178,
            weightKg: 76,
            activityLevel: .moderate,
            goalType: goalType,
            nutrientFocus: .none,
            excludedAllergens: [],
            excludedProducts: [],
            excludedGroups: []
        )
    }
}
