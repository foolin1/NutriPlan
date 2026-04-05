import Foundation

enum ShoppingFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case toBuy = "To Buy"
    case bought = "Bought"

    var id: String { rawValue }
}
