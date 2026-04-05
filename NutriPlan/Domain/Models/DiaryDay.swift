import Foundation

struct DiaryDay: Codable, Hashable {
    var entries: [ConsumedFoodEntry]

    static let empty = DiaryDay(entries: [])
}
