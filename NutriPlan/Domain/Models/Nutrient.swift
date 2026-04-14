import Foundation

struct Nutrient: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let unit: String
    let targetPerDay: Double?
    let isVitamin: Bool

    init(
        id: String,
        name: String,
        unit: String,
        targetPerDay: Double? = nil,
        isVitamin: Bool = false
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.targetPerDay = targetPerDay
        self.isVitamin = isVitamin
    }
}

enum NutrientCatalog {
    static let iron = Nutrient(
        id: "iron",
        name: "Железо",
        unit: "мг",
        targetPerDay: 18,
        isVitamin: false
    )

    static let calcium = Nutrient(
        id: "calcium",
        name: "Кальций",
        unit: "мг",
        targetPerDay: 1000,
        isVitamin: false
    )

    static let magnesium = Nutrient(
        id: "magnesium",
        name: "Магний",
        unit: "мг",
        targetPerDay: 400,
        isVitamin: false
    )

    static let vitaminC = Nutrient(
        id: "vitamin_c",
        name: "Витамин C",
        unit: "мг",
        targetPerDay: 90,
        isVitamin: true
    )

    static let focusable: [Nutrient] = [
        iron,
        calcium,
        magnesium,
        vitaminC
    ]

    static let byId: [String: Nutrient] = Dictionary(
        uniqueKeysWithValues: focusable.map { ($0.id, $0) }
    )

    static func nutrient(for id: String) -> Nutrient? {
        byId[id]
    }

    static func nutrient(for focus: NutrientFocus) -> Nutrient? {
        guard let nutrientId = focus.nutrientId else { return nil }
        return byId[nutrientId]
    }

    static func focusedAmount(
        in nutrients: [String: Double],
        for focus: NutrientFocus
    ) -> Double {
        guard let nutrientId = focus.nutrientId else { return 0 }
        return nutrients[nutrientId, default: 0]
    }

    static func recipeBonus(
        for focus: NutrientFocus,
        amount: Double
    ) -> Double {
        switch focus {
        case .none:
            return 0
        case .iron:
            return min(amount * 4.0, 12.0)
        case .calcium:
            return min(amount * 0.035, 12.0)
        case .magnesium:
            return min(amount * 0.05, 12.0)
        case .vitaminC:
            return min(amount * 0.12, 12.0)
        }
    }

    static func dayPlanBonus(
        for focus: NutrientFocus,
        amount: Double
    ) -> Double {
        switch focus {
        case .none:
            return 0
        case .iron:
            return min(amount * 2.0, 10.0)
        case .calcium:
            return min(amount * 0.02, 10.0)
        case .magnesium:
            return min(amount * 0.03, 10.0)
        case .vitaminC:
            return min(amount * 0.08, 10.0)
        }
    }
}
