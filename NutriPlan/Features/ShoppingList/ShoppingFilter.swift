import Foundation

enum ShoppingFilter: String, CaseIterable, Identifiable {
    case all = "Все"
    case toBuy = "Купить"
    case bought = "Куплено"

    var id: String { rawValue }
}
