import Foundation
import Testing
@testable import NutriPlan

@MainActor
struct ManualDiaryOrderingTests {
    @Test("Ручные записи в дневнике сортируются по типу приёма пищи")
    func manualEntriesAreSortedByMealType() {
        let sessionStore = TestSessionStore()
        let vm = PlanViewModel(sessionStore: sessionStore)

        vm.addManualFoodToDiary(
            foodId: "banana",
            grams: 100,
            mealType: .dinner
        )

        vm.addManualFoodToDiary(
            foodId: "apple",
            grams: 100,
            mealType: .breakfast
        )

        vm.addManualFoodToDiary(
            foodId: "greek_yogurt",
            grams: 150,
            mealType: .snack
        )

        let mealTypes = vm.diaryDay.entries.map(\.mealType)

        #expect(mealTypes.count == 3)
        #expect(mealTypes[0] == .breakfast)
        #expect(mealTypes[1] == .dinner)
        #expect(mealTypes[2] == .snack)
    }

    @Test("Ручная запись сохраняет понятный заголовок с названием продукта и граммовкой")
    func manualEntryTitleIsHumanReadable() throws {
        let sessionStore = TestSessionStore()
        let vm = PlanViewModel(sessionStore: sessionStore)

        vm.addManualFoodToDiary(
            foodId: "milk",
            grams: 200,
            mealType: .snack
        )

        let entry = try #require(vm.diaryDay.entries.first)

        #expect(entry.title.contains("Молоко"))
        #expect(entry.title.contains("200 г"))
    }
}
