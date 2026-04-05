import Foundation

struct ShoppingItem: Identifiable, Hashable {
    let id: String          // foodId
    let name: String
    var grams: Double
    let categoryKey: String // ключ локализации, например "category.meat"
}
