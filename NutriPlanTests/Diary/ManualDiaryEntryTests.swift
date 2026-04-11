import Foundation
import Testing
@testable import NutriPlan

@MainActor
struct ManualDiaryEntryTests {
    @Test("Ручное добавление продукта создаёт запись и округляет граммовку до шага 25 г")
    func manualDiaryEntryIsAddedAndRounded() throws {
        let sessionStore = TestSessionStore()
        let vm = PlanViewModel(sessionStore: sessionStore)

        vm.addManualFoodToDiary(
            foodId: "banana",
            grams: 138,
            mealType: .lunch
        )

        #expect(vm.diaryDay.entries.count == 1)

        let entry = try #require(vm.diaryDay.entries.first)

        #expect(entry.mealType == .lunch)
        #expect(entry.recipe.ingredients.count == 1)
        #expect(entry.recipe.ingredients.first?.foodId == "banana")
        #expect(entry.recipe.ingredients.first?.grams == 150)
        #expect(entry.title.contains("150 г"))
    }
}
