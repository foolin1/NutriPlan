import Foundation

struct FoodGroupOption: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
}

enum FoodGroupCatalog {
    static let all: [FoodGroupOption] = [
        .init(id: "citrus", title: "Цитрусовые", subtitle: "Апельсин, лимон, грейпфрут и похожие фрукты"),
        .init(id: "berries", title: "Ягоды", subtitle: "Черника, клубника, малина и похожие ягоды"),
        .init(id: "dairy", title: "Молочные продукты", subtitle: "Молоко, йогурт, творог и похожие продукты"),
        .init(id: "nuts", title: "Орехи", subtitle: "Миндаль, грецкий орех, арахисовая паста и похожие продукты"),
        .init(id: "legumes", title: "Бобовые", subtitle: "Чечевица, нут, фасоль и похожие продукты"),
        .init(id: "seafood", title: "Рыба и морепродукты", subtitle: "Лосось, тунец и другие морепродукты"),
        .init(id: "eggs", title: "Яйца", subtitle: "Яйца и продукты на их основе"),
        .init(id: "poultry", title: "Птица", subtitle: "Курица, индейка и похожие продукты")
    ]

    static func title(for id: String) -> String {
        all.first(where: { $0.id == id })?.title ?? id
    }
}
