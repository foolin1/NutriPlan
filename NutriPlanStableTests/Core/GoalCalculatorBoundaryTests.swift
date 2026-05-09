import XCTest
@testable import NutriPlan

final class GoalCalculatorBoundaryTests: XCTestCase {

    func testTargetCaloriesAreCappedAtUpperLimit() {
        let profile = UserProfile(
            sex: .male,
            age: 25,
            heightCm: 210,
            weightKg: 250,
            activityLevel: .high,
            goalType: .gainWeight
        )

        let goal = GoalCalculator.calculate(for: profile)

        XCTAssertEqual(goal.targetCalories, 4200)
    }

    func testTargetCaloriesAreRoundedToNearestTen() {
        let profile = UserProfile(
            sex: .male,
            age: 33,
            heightCm: 181,
            weightKg: 83,
            activityLevel: .moderate,
            goalType: .maintainWeight
        )

        let goal = GoalCalculator.calculate(for: profile)

        XCTAssertEqual(goal.targetCalories % 10, 0)
    }

    func testLoseWeightGoalKeepsMinimumCarbs() {
        let profile = UserProfile(
            sex: .female,
            age: 40,
            heightCm: 155,
            weightKg: 45,
            activityLevel: .low,
            goalType: .loseWeight
        )

        let goal = GoalCalculator.calculate(for: profile)

        XCTAssertGreaterThanOrEqual(goal.carbsGrams, 90)
    }

    func testMaintainWeightGoalKeepsMinimumCarbs() {
        let profile = UserProfile(
            sex: .male,
            age: 35,
            heightCm: 175,
            weightKg: 70,
            activityLevel: .low,
            goalType: .maintainWeight
        )

        let goal = GoalCalculator.calculate(for: profile)

        XCTAssertGreaterThanOrEqual(goal.carbsGrams, 120)
    }

    func testGainWeightGoalKeepsMinimumCarbs() {
        let profile = UserProfile(
            sex: .male,
            age: 25,
            heightCm: 180,
            weightKg: 75,
            activityLevel: .moderate,
            goalType: .gainWeight
        )

        let goal = GoalCalculator.calculate(for: profile)

        XCTAssertGreaterThanOrEqual(goal.carbsGrams, 150)
    }

    func testActivityLevelMultiplierIncreasesTargetCalories() {
        let lowActivityProfile = UserProfile(
            sex: .male,
            age: 25,
            heightCm: 180,
            weightKg: 80,
            activityLevel: .low,
            goalType: .maintainWeight
        )

        let highActivityProfile = UserProfile(
            sex: .male,
            age: 25,
            heightCm: 180,
            weightKg: 80,
            activityLevel: .high,
            goalType: .maintainWeight
        )

        let lowGoal = GoalCalculator.calculate(for: lowActivityProfile)
        let highGoal = GoalCalculator.calculate(for: highActivityProfile)

        XCTAssertGreaterThan(highGoal.targetCalories, lowGoal.targetCalories)
    }

    func testGoalTypeCalorieAdjustmentChangesTargetCaloriesInExpectedOrder() {
        let loseProfile = UserProfile(
            sex: .male,
            age: 28,
            heightCm: 178,
            weightKg: 82,
            activityLevel: .moderate,
            goalType: .loseWeight
        )

        let maintainProfile = UserProfile(
            sex: .male,
            age: 28,
            heightCm: 178,
            weightKg: 82,
            activityLevel: .moderate,
            goalType: .maintainWeight
        )

        let gainProfile = UserProfile(
            sex: .male,
            age: 28,
            heightCm: 178,
            weightKg: 82,
            activityLevel: .moderate,
            goalType: .gainWeight
        )

        let loseGoal = GoalCalculator.calculate(for: loseProfile)
        let maintainGoal = GoalCalculator.calculate(for: maintainProfile)
        let gainGoal = GoalCalculator.calculate(for: gainProfile)

        XCTAssertLessThan(loseGoal.targetCalories, maintainGoal.targetCalories)
        XCTAssertLessThan(maintainGoal.targetCalories, gainGoal.targetCalories)
    }
}
