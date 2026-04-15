import Foundation

enum ShoppingGroupingMode: String, CaseIterable, Identifiable {
    case category = "Категории"
    case status = "Статус"

    var id: String { rawValue }
}
