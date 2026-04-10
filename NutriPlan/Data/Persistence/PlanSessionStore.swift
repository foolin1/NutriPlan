import Foundation

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
    let inputSignature: PlanInputSignature
    let dayPlan: DayPlan
    let diaryDay: DiaryDay
}

protocol PlanSessionStore {
    func load() -> PersistedPlanSession?
    func save(
        inputSignature: PlanInputSignature,
        dayPlan: DayPlan,
        diaryDay: DiaryDay
    )
    func clear()
}

final class UserDefaultsPlanSessionStore: PlanSessionStore {
    private let key = "nutriplan.persistedPlanSession"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> PersistedPlanSession? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(PersistedPlanSession.self, from: data)
        } catch {
            print("Failed to load persisted plan session: \(error)")
            return nil
        }
    }

    func save(
        inputSignature: PlanInputSignature,
        dayPlan: DayPlan,
        diaryDay: DiaryDay
    ) {
        let payload = PersistedPlanSession(
            inputSignature: inputSignature,
            dayPlan: dayPlan,
            diaryDay: diaryDay
        )

        do {
            let data = try JSONEncoder().encode(payload)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Failed to save persisted plan session: \(error)")
        }
    }

    func clear() {
        userDefaults.removeObject(forKey: key)
    }
}
