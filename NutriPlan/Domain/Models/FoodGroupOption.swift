import Foundation

struct FoodGroupOption: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
}

enum FoodGroupCatalog {
    static let all: [FoodGroupOption] = [
        .init(id: "citrus", title: "Citrus", subtitle: "Orange, lemon, grapefruit and similar fruits"),
        .init(id: "berries", title: "Berries", subtitle: "Blueberries, strawberries, raspberries and similar fruits"),
        .init(id: "dairy", title: "Dairy", subtitle: "Milk, yogurt, cottage cheese and similar products"),
        .init(id: "nuts", title: "Nuts", subtitle: "Almonds, walnuts, peanut butter and similar products"),
        .init(id: "legumes", title: "Legumes", subtitle: "Lentils, chickpeas, beans and similar products"),
        .init(id: "seafood", title: "Seafood", subtitle: "Salmon, tuna and other fish or seafood"),
        .init(id: "eggs", title: "Eggs", subtitle: "Whole eggs and egg-based products"),
        .init(id: "poultry", title: "Poultry", subtitle: "Chicken, turkey and similar products")
    ]

    static func title(for id: String) -> String {
        all.first(where: { $0.id == id })?.title ?? id
    }
}
