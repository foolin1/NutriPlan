import Foundation

enum ShoppingFilter: String, CaseIterable, Identifiable {
    case all = "Все"
    case toBuy = "Осталось"
    case bought = "Куплено"

    var id: String { rawValue }
}
