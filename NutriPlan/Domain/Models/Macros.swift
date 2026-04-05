import Foundation

/// БЖУ + калории
struct Macros: Codable, Hashable {
    var calories: Double
    var protein: Double
    var fat: Double
    var carbs: Double

    static let zero = Macros(calories: 0, protein: 0, fat: 0, carbs: 0)

    static func + (lhs: Macros, rhs: Macros) -> Macros {
        Macros(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            fat: lhs.fat + rhs.fat,
            carbs: lhs.carbs + rhs.carbs
        )
    }

    static func * (lhs: Macros, factor: Double) -> Macros {
        Macros(
            calories: lhs.calories * factor,
            protein: lhs.protein * factor,
            fat: lhs.fat * factor,
            carbs: lhs.carbs * factor
        )
    }
}
