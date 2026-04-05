import Foundation

enum NutrientFocus: String, CaseIterable, Codable, Identifiable {
    case none
    case iron

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none:
            return "No micronutrient focus"
        case .iron:
            return "Iron support"
        }
    }

    var shortTitle: String {
        switch self {
        case .none:
            return "None"
        case .iron:
            return "Iron"
        }
    }

    var descriptionText: String {
        switch self {
        case .none:
            return "The planner will focus on calories and macronutrients only."
        case .iron:
            return "The planner will prefer meals richer in iron when possible."
        }
    }
}
