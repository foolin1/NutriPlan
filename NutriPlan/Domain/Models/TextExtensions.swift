import Foundation

extension BiologicalSex {
    var uiTitle: String {
        switch self {
        case .male: return "Мужской"
        case .female: return "Женский"
        }
    }
}

extension ActivityLevel {
    var uiTitle: String {
        switch self {
        case .low: return "Низкая активность"
        case .moderate: return "Умеренная активность"
        case .high: return "Высокая активность"
        }
    }
}

extension GoalType {
    var uiTitle: String {
        switch self {
        case .loseWeight: return "Снижение веса"
        case .maintainWeight: return "Поддержание веса"
        case .gainWeight: return "Набор веса"
        }
    }
}

extension MealType {
    var uiTitle: String {
        switch self {
        case .breakfast: return "Завтрак"
        case .lunch: return "Обед"
        case .dinner: return "Ужин"
        case .snack: return "Перекус"
        }
    }
}

extension NutrientFocus {
    var uiTitle: String {
        switch self {
        case .none:
            return "Нет"
        case .iron:
            return "Железо"
        case .calcium:
            return "Кальций"
        case .magnesium:
            return "Магний"
        case .vitaminC:
            return "Витамин C"
        }
    }

    var uiDescription: String {
        switch self {
        case .none:
            return "Дополнительный акцент на микронутриентах не используется."
        case .iron:
            return "Планировщик будет отдавать приоритет блюдам и продуктам с более высоким содержанием железа."
        case .calcium:
            return "Планировщик будет отдавать приоритет блюдам и продуктам с более высоким содержанием кальция."
        case .magnesium:
            return "Планировщик будет отдавать приоритет блюдам и продуктам с более высоким содержанием магния."
        case .vitaminC:
            return "Планировщик будет отдавать приоритет блюдам и продуктам с более высоким содержанием витамина C."
        }
    }
}
