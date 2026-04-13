import Foundation

enum DayIdentifier {
    static func current(
        date: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian),
        timeZone: TimeZone = .current
    ) -> String {
        var calendar = calendar
        calendar.timeZone = timeZone

        let components = calendar.dateComponents([.year, .month, .day], from: date)

        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0

        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

struct PlanInputSignature: Codable, Equatable {
    let sex: BiologicalSex?
    let age: Int?
    let heightCm: Int?
    let weightKg: Int?
    let activityLevel: ActivityLevel?
    let goalType: GoalType?
    let nutrientFocus: NutrientFocus?

    let excludedAllergens: [String]
    let excludedProducts: [String]
    let excludedGroups: [String]

    let targetCalories: Int?
    let proteinGrams: Int?
    let fatGrams: Int?
    let carbsGrams: Int?
}

struct PersistedPlanSession: Codable {
    let dayId: String
    let savedAt: Date
    let inputSignature: PlanInputSignature
    let dayPlan: DayPlan
    let diaryDay: DiaryDay
    let checkedShoppingItemIds: [String]
}

struct PlanHistoryRecord: Codable, Identifiable {
    let dayId: String
    let savedAt: Date
    let inputSignature: PlanInputSignature
    let dayPlan: DayPlan
    let diaryDay: DiaryDay
    let checkedShoppingItemIds: [String]

    var id: String { dayId }

    init(from session: PersistedPlanSession) {
        self.dayId = session.dayId
        self.savedAt = session.savedAt
        self.inputSignature = session.inputSignature
        self.dayPlan = session.dayPlan
        self.diaryDay = session.diaryDay
        self.checkedShoppingItemIds = session.checkedShoppingItemIds
    }
}

protocol PlanSessionStore {
    func loadCurrentDay() -> PersistedPlanSession?
    func saveCurrentDay(
        dayId: String,
        inputSignature: PlanInputSignature,
        dayPlan: DayPlan,
        diaryDay: DiaryDay,
        checkedShoppingItemIds: Set<String>
    )
    func clearCurrentDay()

    func loadHistory() -> [PlanHistoryRecord]
    func appendHistoryRecord(from session: PersistedPlanSession)
    func clearHistory()
}

extension PlanSessionStore {
    func clear() {
        clearCurrentDay()
    }
}

final class UserDefaultsPlanSessionStore: PlanSessionStore {
    private enum GlobalLegacyKeys {
        static let currentDay = "nutriplan.persistedPlanSession.v2"
        static let history = "nutriplan.planHistory.v1"

        static let legacySession = "nutriplan.persistedPlanSession"
        static let legacyCheckedIds = "shopping.checkedIds"
    }

    private struct LegacyPersistedPlanSession: Codable {
        let inputSignature: PlanInputSignature
        let dayPlan: DayPlan
        let diaryDay: DiaryDay
    }

    private let userDefaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private let currentDayKey: String
    private let historyKey: String

    init(
        accountId: String,
        userDefaults: UserDefaults = .standard,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.userDefaults = userDefaults
        self.decoder = decoder
        self.encoder = encoder

        let namespace = Self.namespace(for: accountId)
        self.currentDayKey = "nutriplan.account.\(namespace).currentDay.v1"
        self.historyKey = "nutriplan.account.\(namespace).history.v1"
    }

    func loadCurrentDay() -> PersistedPlanSession? {
        if let current = loadValue(PersistedPlanSession.self, forKey: currentDayKey) {
            return current
        }

        migrateCurrentDayIfNeeded()
        return loadValue(PersistedPlanSession.self, forKey: currentDayKey)
    }

    func saveCurrentDay(
        dayId: String,
        inputSignature: PlanInputSignature,
        dayPlan: DayPlan,
        diaryDay: DiaryDay,
        checkedShoppingItemIds: Set<String>
    ) {
        let payload = PersistedPlanSession(
            dayId: dayId,
            savedAt: Date(),
            inputSignature: inputSignature,
            dayPlan: dayPlan,
            diaryDay: diaryDay,
            checkedShoppingItemIds: checkedShoppingItemIds.sorted()
        )

        saveValue(payload, forKey: currentDayKey)
    }

    func clearCurrentDay() {
        userDefaults.removeObject(forKey: currentDayKey)
    }

    func loadHistory() -> [PlanHistoryRecord] {
        if let scoped = loadValue([PlanHistoryRecord].self, forKey: historyKey) {
            return scoped
        }

        migrateHistoryIfNeeded()
        return loadValue([PlanHistoryRecord].self, forKey: historyKey) ?? []
    }

    func appendHistoryRecord(from session: PersistedPlanSession) {
        let shouldStore =
            !session.dayPlan.meals.isEmpty ||
            !session.diaryDay.entries.isEmpty ||
            !session.checkedShoppingItemIds.isEmpty

        guard shouldStore else { return }

        var records = loadHistory()
        let newRecord = PlanHistoryRecord(from: session)

        records.removeAll { $0.dayId == newRecord.dayId }
        records.append(newRecord)
        records.sort { $0.dayId > $1.dayId }

        saveValue(records, forKey: historyKey)
    }

    func clearHistory() {
        userDefaults.removeObject(forKey: historyKey)
    }

    private func migrateCurrentDayIfNeeded() {
        guard loadValue(PersistedPlanSession.self, forKey: currentDayKey) == nil else {
            return
        }

        if let globalCurrent = loadValue(PersistedPlanSession.self, forKey: GlobalLegacyKeys.currentDay) {
            saveValue(globalCurrent, forKey: currentDayKey)
            userDefaults.removeObject(forKey: GlobalLegacyKeys.currentDay)
            return
        }

        if let legacy = loadValue(LegacyPersistedPlanSession.self, forKey: GlobalLegacyKeys.legacySession) {
            let migrated = PersistedPlanSession(
                dayId: DayIdentifier.current(),
                savedAt: Date(),
                inputSignature: legacy.inputSignature,
                dayPlan: legacy.dayPlan,
                diaryDay: legacy.diaryDay,
                checkedShoppingItemIds: loadLegacyCheckedShoppingItemIds()
            )

            saveValue(migrated, forKey: currentDayKey)
            userDefaults.removeObject(forKey: GlobalLegacyKeys.legacySession)
            userDefaults.removeObject(forKey: GlobalLegacyKeys.legacyCheckedIds)
        }
    }

    private func migrateHistoryIfNeeded() {
        guard loadValue([PlanHistoryRecord].self, forKey: historyKey) == nil else {
            return
        }

        if let globalHistory = loadValue([PlanHistoryRecord].self, forKey: GlobalLegacyKeys.history) {
            saveValue(globalHistory, forKey: historyKey)
            userDefaults.removeObject(forKey: GlobalLegacyKeys.history)
        }
    }

    private func loadLegacyCheckedShoppingItemIds() -> [String] {
        guard let rawValue = userDefaults.string(forKey: GlobalLegacyKeys.legacyCheckedIds) else {
            return []
        }

        return rawValue
            .split(separator: ",")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private func loadValue<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("Failed to load value for key '\(key)': \(error)")
            return nil
        }
    }

    private func saveValue<T: Encodable>(_ value: T, forKey key: String) {
        do {
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Failed to save value for key '\(key)': \(error)")
        }
    }

    private static func namespace(for accountId: String) -> String {
        accountId
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
    }
}
