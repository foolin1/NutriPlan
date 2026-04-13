import Foundation

struct ProfileSnapshot: Identifiable, Equatable {
    let id: String
    let recordedAt: Date
    let profile: UserProfile

    var shortWeightText: String {
        "\(Int(profile.weightKg.rounded())) кг"
    }

    var shortHeightText: String {
        "\(Int(profile.heightCm.rounded())) см"
    }

    var shortGoalText: String {
        profile.goalType.ruTitle
    }

    var shortActivityText: String {
        profile.activityLevel.ruTitle
    }

    var shortNutrientFocusText: String {
        profile.nutrientFocus.displayName
    }

    var excludedGroupsSummary: String {
        if profile.excludedGroups.isEmpty {
            return "Нет"
        }

        return profile.excludedGroups
            .sorted()
            .map { FoodGroupCatalog.title(for: $0) }
            .joined(separator: ", ")
    }
}
