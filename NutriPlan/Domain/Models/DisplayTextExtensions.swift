import Foundation

extension BiologicalSex {
    var ruTitle: String {
        switch self {
        case .male: return "Мужской"
        case .female: return "Женский"
        }
    }
}

extension ActivityLevel {
    var ruTitle: String {
        switch self {
        case .low: return "Низкая активность"
        case .moderate: return "Умеренная активность"
        case .high: return "Высокая активность"
        }
    }
}

extension GoalType {
    var ruTitle: String {
        switch self {
        case .loseWeight: return "Снижение веса"
        case .maintainWeight: return "Поддержание веса"
        case .gainWeight: return "Набор веса"
        }
    }
}

extension MealType {
    var ruTitle: String {
        switch self {
        case .breakfast: return "Завтрак"
        case .lunch: return "Обед"
        case .dinner: return "Ужин"
        case .snack: return "Перекус"
        }
    }
}
