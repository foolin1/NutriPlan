import XCTest
@testable import NutriPlan

final class NutrientCatalogTests: XCTestCase {

    func testNutrientForFocusReturnsExpectedNutrient() {
        let nutrient = NutrientCatalog.nutrient(for: .iron)

        XCTAssertEqual(nutrient?.id, "iron")
        XCTAssertEqual(nutrient?.name, "Железо")
        XCTAssertEqual(nutrient?.unit, "мг")
    }

    func testFocusedAmountReturnsCorrectValueForSelectedFocus() {
        let nutrients: [String: Double] = [
            "iron": 7.5,
            "calcium": 320,
            "vitamin_c": 45
        ]

        let ironAmount = NutrientCatalog.focusedAmount(in: nutrients, for: .iron)
        let calciumAmount = NutrientCatalog.focusedAmount(in: nutrients, for: .calcium)
        let noneAmount = NutrientCatalog.focusedAmount(in: nutrients, for: .none)

        XCTAssertEqual(ironAmount, 7.5)
        XCTAssertEqual(calciumAmount, 320)
        XCTAssertEqual(noneAmount, 0)
    }

    func testRecipeBonusForIronIsCalculatedAndCapped() {
        XCTAssertEqual(NutrientCatalog.recipeBonus(for: .iron, amount: 1), 4.0)
        XCTAssertEqual(NutrientCatalog.recipeBonus(for: .iron, amount: 10), 12.0)
    }

    func testDayPlanBonusForCalciumIsCalculatedAndCapped() {
        XCTAssertEqual(NutrientCatalog.dayPlanBonus(for: .calcium, amount: 100), 2.0)
        XCTAssertEqual(NutrientCatalog.dayPlanBonus(for: .calcium, amount: 500), 10.0)
        XCTAssertEqual(NutrientCatalog.dayPlanBonus(for: .calcium, amount: 1000), 10.0)
    }

    func testResolveNutrientFocusSupportsDifferentStoredFormats() {
        XCTAssertEqual(NutrientFocus.resolve(from: nil), .none)
        XCTAssertEqual(NutrientFocus.resolve(from: "iron"), .iron)
        XCTAssertEqual(NutrientFocus.resolve(from: "Железо"), .iron)
        XCTAssertEqual(NutrientFocus.resolve(from: "vitamin c"), .vitaminC)
        XCTAssertEqual(NutrientFocus.resolve(from: "vitamin_c"), .vitaminC)
        XCTAssertEqual(NutrientFocus.resolve(from: "unknown_value"), .none)
    }

    func testFocusableContainsExpectedCoreNutrients() {
        let ids = Set(NutrientCatalog.focusable.map(\.id))

        XCTAssertTrue(ids.contains("iron"))
        XCTAssertTrue(ids.contains("calcium"))
        XCTAssertTrue(ids.contains("magnesium"))
        XCTAssertTrue(ids.contains("vitamin_c"))
        XCTAssertEqual(ids.count, 4)
    }
}
