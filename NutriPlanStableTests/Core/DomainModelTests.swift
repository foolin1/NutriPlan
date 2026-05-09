import XCTest
@testable import NutriPlan

final class DomainModelTests: XCTestCase {

    func testMacrosZeroContainsOnlyZeroValues() {
        let macros = Macros.zero

        XCTAssertEqual(macros.calories, 0)
        XCTAssertEqual(macros.protein, 0)
        XCTAssertEqual(macros.fat, 0)
        XCTAssertEqual(macros.carbs, 0)
    }

    func testMacrosAdditionSumsAllFields() {
        let left = Macros(
            calories: 120,
            protein: 10,
            fat: 4,
            carbs: 15
        )
        let right = Macros(
            calories: 80,
            protein: 6,
            fat: 2,
            carbs: 9
        )

        let result = left + right

        XCTAssertEqual(result.calories, 200)
        XCTAssertEqual(result.protein, 16)
        XCTAssertEqual(result.fat, 6)
        XCTAssertEqual(result.carbs, 24)
    }

    func testMacrosMultiplicationScalesAllFields() {
        let macros = Macros(
            calories: 200,
            protein: 20,
            fat: 10,
            carbs: 30
        )

        let result = macros * 0.5

        XCTAssertEqual(result.calories, 100)
        XCTAssertEqual(result.protein, 10)
        XCTAssertEqual(result.fat, 5)
        XCTAssertEqual(result.carbs, 15)
    }

    func testPlanComparisonMetricCalculatesDeltaAndCompletionPercent() {
        let metric = PlanComparisonMetric(
            title: "Protein",
            unit: "g",
            planned: 120,
            actual: 90
        )

        XCTAssertEqual(metric.delta, -30)
        XCTAssertEqual(metric.completionPercent, 75)
    }

    func testPlanComparisonMetricReturnsZeroPercentWhenPlannedValueIsZero() {
        let metric = PlanComparisonMetric(
            title: "Iron",
            unit: "mg",
            planned: 0,
            actual: 5
        )

        XCTAssertEqual(metric.delta, 5)
        XCTAssertEqual(metric.completionPercent, 0)
    }

    func testNutrientFocusResolvesAliasesAndRussianNames() {
        XCTAssertEqual(NutrientFocus.resolve(from: nil), .none)
        XCTAssertEqual(NutrientFocus.resolve(from: "iron"), .iron)
        XCTAssertEqual(NutrientFocus.resolve(from: "Железо"), .iron)
        XCTAssertEqual(NutrientFocus.resolve(from: "vitamin c"), .vitaminC)
        XCTAssertEqual(NutrientFocus.resolve(from: "витамин c"), .vitaminC)
        XCTAssertEqual(NutrientFocus.resolve(from: "unknown value"), .none)
    }

    func testNutrientFocusProvidesDisplayValues() {
        XCTAssertNil(NutrientFocus.none.nutrientId)

        XCTAssertEqual(NutrientFocus.iron.nutrientId, "iron")
        XCTAssertEqual(NutrientFocus.calcium.nutrientId, "calcium")
        XCTAssertEqual(NutrientFocus.magnesium.nutrientId, "magnesium")
        XCTAssertEqual(NutrientFocus.vitaminC.nutrientId, "vitamin_c")

        XCTAssertEqual(NutrientFocus.vitaminC.shortTitle, "Vit C")
        XCTAssertEqual(NutrientFocus.iron.displayName, "Железо")
    }

    func testUserProfileDecodingUsesDefaultsForMissingOptionalFields() throws {
        let json = """
        {
            "sex": "Male",
            "age": 25,
            "heightCm": 180,
            "weightKg": 78,
            "activityLevel": "Moderate activity",
            "goalType": "Maintain weight"
        }
        """

        let data = Data(json.utf8)
        let profile = try JSONDecoder().decode(UserProfile.self, from: data)

        XCTAssertEqual(profile.sex, .male)
        XCTAssertEqual(profile.age, 25)
        XCTAssertEqual(profile.heightCm, 180)
        XCTAssertEqual(profile.weightKg, 78)
        XCTAssertEqual(profile.activityLevel, .moderate)
        XCTAssertEqual(profile.goalType, .maintainWeight)
        XCTAssertEqual(profile.nutrientFocus, .none)
        XCTAssertTrue(profile.excludedAllergens.isEmpty)
        XCTAssertTrue(profile.excludedProducts.isEmpty)
        XCTAssertTrue(profile.excludedGroups.isEmpty)
    }

    func testUserProfileCodablePreservesRestrictionsAndNutrientFocus() throws {
        let profile = UserProfile(
            sex: .female,
            age: 30,
            heightCm: 168,
            weightKg: 62,
            activityLevel: .low,
            goalType: .loseWeight,
            nutrientFocus: .vitaminC,
            excludedAllergens: ["nuts"],
            excludedProducts: ["avocado"],
            excludedGroups: ["dairy"]
        )

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)

        XCTAssertEqual(decoded.sex, .female)
        XCTAssertEqual(decoded.age, 30)
        XCTAssertEqual(decoded.heightCm, 168)
        XCTAssertEqual(decoded.weightKg, 62)
        XCTAssertEqual(decoded.activityLevel, .low)
        XCTAssertEqual(decoded.goalType, .loseWeight)
        XCTAssertEqual(decoded.nutrientFocus, .vitaminC)
        XCTAssertEqual(decoded.excludedAllergens, ["nuts"])
        XCTAssertEqual(decoded.excludedProducts, ["avocado"])
        XCTAssertEqual(decoded.excludedGroups, ["dairy"])
    }
}
