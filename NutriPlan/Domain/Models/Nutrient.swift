import Foundation

/// Микронутриент (витамин/минерал)
struct Nutrient: Identifiable, Codable, Hashable {
    /// Удобно использовать строковые идентификаторы: "iron", "vitamin_c" и т.д.
    let id: String
    let name: String
    let unit: String   // "mg", "µg", "g", "IU" и т.п.
}
