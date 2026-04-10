import Foundation

enum BiologicalSex: String, CaseIterable, Codable, Identifiable {
    case male = "Male"
    case female = "Female"

    var id: String { rawValue }
}

enum ActivityLevel: String, CaseIterable, Codable, Identifiable {
    case low = "Low activity"
    case moderate = "Moderate activity"
    case high = "High activity"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .low:
            return 1.2
        case .moderate:
            return 1.55
        case .high:
            return 1.725
        }
    }
}

enum GoalType: String, CaseIterable, Codable, Identifiable {
    case loseWeight = "Lose weight"
    case maintainWeight = "Maintain weight"
    case gainWeight = "Gain weight"

    var id: String { rawValue }

    var calorieAdjustment: Double {
        switch self {
        case .loseWeight:
            return 0.85
        case .maintainWeight:
            return 1.0
        case .gainWeight:
            return 1.10
        }
    }

    var proteinMultiplier: Double {
        switch self {
        case .loseWeight:
            return 1.8
        case .maintainWeight:
            return 1.6
        case .gainWeight:
            return 1.8
        }
    }

    var fatMultiplier: Double {
        switch self {
        case .loseWeight:
            return 0.8
        case .maintainWeight:
            return 0.9
        case .gainWeight:
            return 1.0
        }
    }
}

struct UserProfile: Codable, Hashable {
    var sex: BiologicalSex
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var activityLevel: ActivityLevel
    var goalType: GoalType
    var nutrientFocus: NutrientFocus

    var excludedAllergens: [String]
    var excludedProducts: [String]
    var excludedGroups: [String]

    init(
        sex: BiologicalSex,
        age: Int,
        heightCm: Double,
        weightKg: Double,
        activityLevel: ActivityLevel,
        goalType: GoalType,
        nutrientFocus: NutrientFocus = .none,
        excludedAllergens: [String] = [],
        excludedProducts: [String] = [],
        excludedGroups: [String] = []
    ) {
        self.sex = sex
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activityLevel = activityLevel
        self.goalType = goalType
        self.nutrientFocus = nutrientFocus
        self.excludedAllergens = excludedAllergens
        self.excludedProducts = excludedProducts
        self.excludedGroups = excludedGroups
    }

    enum CodingKeys: String, CodingKey {
        case sex
        case age
        case heightCm
        case weightKg
        case activityLevel
        case goalType
        case nutrientFocus
        case excludedAllergens
        case excludedProducts
        case excludedGroups
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        sex = try container.decode(BiologicalSex.self, forKey: .sex)
        age = try container.decode(Int.self, forKey: .age)
        heightCm = try container.decode(Double.self, forKey: .heightCm)
        weightKg = try container.decode(Double.self, forKey: .weightKg)
        activityLevel = try container.decode(ActivityLevel.self, forKey: .activityLevel)
        goalType = try container.decode(GoalType.self, forKey: .goalType)
        nutrientFocus = try container.decodeIfPresent(NutrientFocus.self, forKey: .nutrientFocus) ?? .none
        excludedAllergens = try container.decodeIfPresent([String].self, forKey: .excludedAllergens) ?? []
        excludedProducts = try container.decodeIfPresent([String].self, forKey: .excludedProducts) ?? []
        excludedGroups = try container.decodeIfPresent([String].self, forKey: .excludedGroups) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(sex, forKey: .sex)
        try container.encode(age, forKey: .age)
        try container.encode(heightCm, forKey: .heightCm)
        try container.encode(weightKg, forKey: .weightKg)
        try container.encode(activityLevel, forKey: .activityLevel)
        try container.encode(goalType, forKey: .goalType)
        try container.encode(nutrientFocus, forKey: .nutrientFocus)
        try container.encode(excludedAllergens, forKey: .excludedAllergens)
        try container.encode(excludedProducts, forKey: .excludedProducts)
        try container.encode(excludedGroups, forKey: .excludedGroups)
    }
}
