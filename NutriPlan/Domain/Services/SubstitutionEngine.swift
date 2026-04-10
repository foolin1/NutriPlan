import Foundation

struct SubstitutionCandidate: Identifiable, Hashable {
    let id: String                 // foodId кандидата
    let name: String
    let score: Double              // итоговая оценка 0...100, больше = лучше
    let deltaMacros: Macros        // candidate - original для того же веса

    // Для объяснимости в UI и дипломе
    let weightedPenalty: Double
    let tagBonus: Double
    let ironDelta: Double?
}

enum SubstitutionEngine {
    static func suggest(
        originalFoodId: String,
        grams: Double,
        foods: [Food],
        foodsById: [String: Food],
        excludedAllergens: Set<String>,
        excludedProducts: Set<String> = [],
        excludedGroups: Set<String> = [],
        requiredTags: Set<String> = []
    ) -> [SubstitutionCandidate]{
        guard let original = foodsById[originalFoodId] else {
            return []
        }

        let factor = grams / 100.0
        let originalMacros = original.macrosPer100g * factor
        let originalIron = original.nutrientsPer100g["iron", default: 0] * factor
        let originalCategory = categoryKey(for: original)

        let normalizedExcludedProducts = Set(
            excludedProducts.map(normalizeText)
        )

        let candidates = foods.filter { food in
            guard food.id != originalFoodId else { return false }
            guard excludedAllergens.isDisjoint(with: food.allergens) else { return false }
            guard requiredTags.isSubset(of: food.tags) else { return false }
            guard excludedGroups.isDisjoint(with: food.groups) else { return false }

            let candidateCategory = categoryKey(for: food)
            guard candidateCategory == originalCategory else { return false }

            let normalizedName = normalizeText(food.name)
            let normalizedId = normalizeText(food.id)

            for excluded in normalizedExcludedProducts {
                if normalizedName.contains(excluded) || normalizedId.contains(excluded) {
                    return false
                }
            }

            return true
        }

        let scored: [SubstitutionCandidate] = candidates.map { candidate in
            let candidateMacros = candidate.macrosPer100g * factor
            let candidateIron = candidate.nutrientsPer100g["iron", default: 0] * factor

            let delta = Macros(
                calories: candidateMacros.calories - originalMacros.calories,
                protein: candidateMacros.protein - originalMacros.protein,
                fat: candidateMacros.fat - originalMacros.fat,
                carbs: candidateMacros.carbs - originalMacros.carbs
            )

            let weightedPenalty = computeWeightedPenalty(
                original: originalMacros,
                candidate: candidateMacros
            )

            let tagBonus = computeTagBonus(
                originalTags: original.tags,
                candidateTags: candidate.tags
            )

            let ironDelta = computeIronDelta(
                originalIron: originalIron,
                candidateIron: candidateIron
            )

            let score = computeScore(
                weightedPenalty: weightedPenalty,
                tagBonus: tagBonus,
                ironDelta: ironDelta
            )

            return SubstitutionCandidate(
                id: candidate.id,
                name: candidate.name,
                score: score,
                deltaMacros: delta,
                weightedPenalty: weightedPenalty,
                tagBonus: tagBonus,
                ironDelta: ironDelta
            )
        }

        return scored
            .sorted {
                if abs($0.score - $1.score) > 0.0001 {
                    return $0.score > $1.score
                }

                return abs($0.deltaMacros.calories) < abs($1.deltaMacros.calories)
            }
            .prefix(5)
            .map { $0 }
    }

    private static func categoryKey(for food: Food) -> String {
        if food.tags.contains("meat") {
            return "meat"
        }

        if food.tags.contains("grain") || food.tags.contains("legume") {
            return "grain"
        }

        if food.tags.contains("vegetable") {
            return "vegetable"
        }

        return "other"
    }

    private static func computeWeightedPenalty(
        original: Macros,
        candidate: Macros
    ) -> Double {
        let caloriesRelative = relativeDelta(
            original: original.calories,
            candidate: candidate.calories,
            fallback: 50
        )

        let proteinRelative = relativeDelta(
            original: original.protein,
            candidate: candidate.protein,
            fallback: 5
        )

        let fatRelative = relativeDelta(
            original: original.fat,
            candidate: candidate.fat,
            fallback: 3
        )

        let carbsRelative = relativeDelta(
            original: original.carbs,
            candidate: candidate.carbs,
            fallback: 5
        )

        let weightedPenalty =
            caloriesRelative * 40
            + proteinRelative * 30
            + fatRelative * 15
            + carbsRelative * 15

        return weightedPenalty
    }

    private static func relativeDelta(
        original: Double,
        candidate: Double,
        fallback: Double
    ) -> Double {
        let denominator = max(abs(original), fallback)
        return abs(candidate - original) / denominator
    }

    private static func computeTagBonus(
        originalTags: Set<String>,
        candidateTags: Set<String>
    ) -> Double {
        let genericTags: Set<String> = [
            "meat",
            "grain",
            "legume",
            "vegetable"
        ]

        let originalSpecific = originalTags.subtracting(genericTags)
        let candidateSpecific = candidateTags.subtracting(genericTags)
        let overlapCount = originalSpecific.intersection(candidateSpecific).count

        return min(Double(overlapCount) * 4.0, 10.0)
    }

    private static func computeIronDelta(
        originalIron: Double,
        candidateIron: Double
    ) -> Double? {
        if abs(originalIron) < 0.0001 && abs(candidateIron) < 0.0001 {
            return nil
        }

        return candidateIron - originalIron
    }

    private static func computeScore(
        weightedPenalty: Double,
        tagBonus: Double,
        ironDelta: Double?
    ) -> Double {
        var score = 100.0 - weightedPenalty + tagBonus

        if let ironDelta {
            score += max(min(ironDelta * 3.0, 6.0), -6.0)
        }

        return min(max(score, 0), 100)
    }

    private static func normalizeText(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
