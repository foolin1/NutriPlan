import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    @Published var sex: BiologicalSex = .male
    @Published var age: Int = 25
    @Published var heightCm: Double = 175
    @Published var weightKg: Double = 75
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var goalType: GoalType = .maintainWeight
    @Published var nutrientFocus: NutrientFocus = .none
    @Published var allergensText: String = ""
    @Published var excludedProductsText: String = ""

    var canContinue: Bool {
        age >= 14 && heightCm >= 120 && weightKg >= 35
    }

    func buildProfile() -> UserProfile {
        UserProfile(
            sex: sex,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel,
            goalType: goalType,
            nutrientFocus: nutrientFocus,
            excludedAllergens: parseList(from: allergensText),
            excludedProducts: parseList(from: excludedProductsText)
        )
    }

    private func parseList(from text: String) -> [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }
}
