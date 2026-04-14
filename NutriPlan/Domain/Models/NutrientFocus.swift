import Foundation

enum NutrientFocus: String, CaseIterable, Codable, Identifiable {
    case none = "none"
    case iron = "iron"
    case calcium = "calcium"
    case magnesium = "magnesium"
    case vitaminC = "vitamin_c"

    var id: String { rawValue }

    var nutrientId: String? {
        switch self {
        case .none:
            return nil
        case .iron:
            return "iron"
        case .calcium:
            return "calcium"
        case .magnesium:
            return "magnesium"
        case .vitaminC:
            return "vitamin_c"
        }
    }

    var displayName: String {
        switch self {
        case .none:
            return "Без дополнительного фокуса"
        case .iron:
            return "Железо"
        case .calcium:
            return "Кальций"
        case .magnesium:
            return "Магний"
        case .vitaminC:
            return "Витамин C"
        }
    }

    var shortTitle: String {
        switch self {
        case .none:
            return "Нет"
        case .iron:
            return "Fe"
        case .calcium:
            return "Ca"
        case .magnesium:
            return "Mg"
        case .vitaminC:
            return "Vit C"
        }
    }

    var descriptionText: String {
        switch self {
        case .none:
            return "План будет ориентироваться в первую очередь на калории и макронутриенты."
        case .iron:
            return "План будет по возможности выбирать блюда с более высоким содержанием железа."
        case .calcium:
            return "План будет по возможности выбирать блюда с более высоким содержанием кальция."
        case .magnesium:
            return "План будет по возможности выбирать блюда с более высоким содержанием магния."
        case .vitaminC:
            return "План будет по возможности выбирать блюда с более высоким содержанием витамина C."
        }
    }

    static func resolve(from storedValue: String?) -> NutrientFocus {
        guard let storedValue else { return .none }

        let normalized = storedValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")

        switch normalized {
        case "none",
             "без дополнительного фокуса",
             "no micronutrient focus":
            return .none

        case "iron",
             "iron support",
             "железо":
            return .iron

        case "calcium",
             "calcium support",
             "кальций":
            return .calcium

        case "magnesium",
             "magnesium support",
             "магний":
            return .magnesium

        case "vitamin_c",
             "vitaminc",
             "vitamin c",
             "vitamin c support",
             "витамин c":
            return .vitaminC

        default:
            return NutrientFocus(rawValue: normalized) ?? .none
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try? container.decode(String.self)
        self = NutrientFocus.resolve(from: raw)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
