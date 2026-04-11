import Foundation

enum NutrientFocus: String, CaseIterable, Codable, Identifiable {
    case none
    case iron

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none:
            return "Без дополнительного фокуса"
        case .iron:
            return "Поддержка железа"
        }
    }

    var shortTitle: String {
        switch self {
        case .none:
            return "Нет"
        case .iron:
            return "Железо"
        }
    }

    var descriptionText: String {
        switch self {
        case .none:
            return "Планировщик будет ориентироваться только на калории и макронутриенты."
        case .iron:
            return "Планировщик будет по возможности отдавать приоритет блюдам с более высоким содержанием железа."
        }
    }
}
