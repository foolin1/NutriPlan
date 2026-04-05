import Foundation

struct SubstitutionCandidate: Identifiable, Hashable {
    let id: String          // foodId candidate
    let name: String
    let score: Double       // чем больше — тем лучше
    let deltaMacros: Macros // разница (candidate - original) для того же веса
}

enum SubstitutionEngine {

    static func suggest(
        originalFoodId: String,
        grams: Double,
        foods: [Food],
        foodsById: [String: Food],
        excludedAllergens: Set<String>,
        requiredTags: Set<String> = []
    ) -> [SubstitutionCandidate] {

        guard let original = foodsById[originalFoodId] else { return [] }

        let factor = grams / 100.0
        let originalMacros = original.macrosPer100g * factor

        let originalCategory = categoryKey(for: original)

        let candidates = foods.filter { f in
            guard f.id != originalFoodId else { return false }
            guard excludedAllergens.isDisjoint(with: f.allergens) else { return false }
            guard requiredTags.isSubset(of: f.tags) else { return false }

            // держим категорию
            let candCategory = categoryKey(for: f)
            return candCategory == originalCategory
        }

        let scored = candidates.map { cand -> SubstitutionCandidate in
            let candMacros = cand.macrosPer100g * factor
            let delta = Macros(
                calories: candMacros.calories - originalMacros.calories,
                protein: candMacros.protein - originalMacros.protein,
                fat: candMacros.fat - originalMacros.fat,
                carbs: candMacros.carbs - originalMacros.carbs
            )
            let score = computeScore(delta: delta)
            return SubstitutionCandidate(id: cand.id, name: cand.name, score: score, deltaMacros: delta)
        }

        return scored
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { $0 }
    }

    private static func categoryKey(for food: Food) -> String {
        if food.tags.contains("meat") { return "meat" }
        if food.tags.contains("grain") { return "grain" }
        if food.tags.contains("vegetable") { return "vegetable" }
        return "other"
    }

    private static func computeScore(delta: Macros) -> Double {
        // штраф за отклонение (веса — часть дипломного объяснения)
        let cal = abs(delta.calories) * 1.0
        let p = abs(delta.protein) * 6.0
        let f = abs(delta.fat) * 4.0
        let c = abs(delta.carbs) * 3.0
        let penalty = cal + p + f + c
        return 1_000.0 - penalty
    }
}
