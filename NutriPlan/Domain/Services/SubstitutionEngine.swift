import Foundation

struct SubstitutionCandidate: Identifiable, Hashable {
    let id: String
    let name: String
    let score: Double
    let deltaMacros: Macros
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
    ) -> [SubstitutionCandidate] {
        guard let original = foodsById[originalFoodId] else {
            return []
        }

        let factor = grams / 100.0
        let originalMacros = original.macrosPer100g * factor
        let originalIron = original.nutrientsPer100g["iron", default: 0] * factor
        let originalCategory = culinaryCategory(for: original)
        let allowedCategories = compatibleCategories(for: originalCategory)

        let normalizedExcludedProducts = Set(
            excludedProducts.map(normalizeText)
        )

        let candidates = foods.filter { food in
            guard food.id != originalFoodId else { return false }
            guard excludedAllergens.isDisjoint(with: food.allergens) else { return false }
            guard requiredTags.isSubset(of: food.tags) else { return false }
            guard excludedGroups.isDisjoint(with: food.groups) else { return false }

            let candidateCategory = culinaryCategory(for: food)
            guard allowedCategories.contains(candidateCategory) else { return false }

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
            let candidateCategory = culinaryCategory(for: candidate)

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

            let categoryBonus = computeCategoryBonus(
                originalCategory: originalCategory,
                candidateCategory: candidateCategory
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
                categoryBonus: categoryBonus,
                tagBonus: tagBonus,
                ironDelta: ironDelta
            )

            return SubstitutionCandidate(
                id: candidate.id,
                name: candidate.name,
                score: score,
                deltaMacros: delta,
                weightedPenalty: weightedPenalty,
                tagBonus: categoryBonus + tagBonus,
                ironDelta: ironDelta
            )
        }

        return scored
            .sorted {
                if abs($0.score - $1.score) > 0.0001 {
                    return $0.score > $1.score
                }

                let leftMacroGap = macroGapMagnitude($0.deltaMacros)
                let rightMacroGap = macroGapMagnitude($1.deltaMacros)

                if abs(leftMacroGap - rightMacroGap) > 0.0001 {
                    return leftMacroGap < rightMacroGap
                }

                return abs($0.deltaMacros.calories) < abs($1.deltaMacros.calories)
            }
            .prefix(8)
            .map { $0 }
    }

    private static func culinaryCategory(for food: Food) -> String {
        if food.groups.contains("seafood") || food.tags.contains("seafood") {
            return "fish"
        }

        if food.groups.contains("poultry")
            || food.groups.contains("red_meat")
            || food.tags.contains("meat") {
            return "meat"
        }

        if food.groups.contains("eggs") || food.tags.contains("egg") {
            return "eggs"
        }

        if food.groups.contains("grain")
            || food.groups.contains("legumes")
            || food.tags.contains("grain")
            || food.tags.contains("legume") {
            return "garnish"
        }

        if food.groups.contains("vegetable") || food.tags.contains("vegetable") {
            return "vegetable"
        }

        if food.groups.contains("berries") {
            return "berries"
        }

        if food.groups.contains("fruit")
            || food.groups.contains("citrus")
            || food.tags.contains("fruit") {
            return "fruit"
        }

        if food.groups.contains("dairy") || food.tags.contains("dairy") {
            return "dairy"
        }

        if food.groups.contains("nuts")
            || food.groups.contains("seeds")
            || food.tags.contains("nut")
            || food.tags.contains("seed") {
            return "nuts"
        }

        if food.groups.contains("protein_alt") {
            return "protein_alt"
        }

        return "other"
    }

    private static func compatibleCategories(for originalCategory: String) -> Set<String> {
        switch originalCategory {
        case "meat":
            return ["meat", "fish"]

        case "fish":
            return ["fish", "meat"]

        case "eggs":
            return ["eggs"]

        case "garnish":
            return ["garnish"]

        case "vegetable":
            return ["vegetable"]

        case "fruit":
            return ["fruit", "berries"]

        case "berries":
            return ["berries", "fruit"]

        case "dairy":
            return ["dairy"]

        case "nuts":
            return ["nuts"]

        case "protein_alt":
            return ["protein_alt"]

        default:
            return [originalCategory]
        }
    }

    private static func computeCategoryBonus(
        originalCategory: String,
        candidateCategory: String
    ) -> Double {
        if originalCategory == candidateCategory {
            return 18.0
        }

        let proteinFamily: Set<String> = ["meat", "fish"]
        let fruitFamily: Set<String> = ["fruit", "berries"]

        if proteinFamily.contains(originalCategory) && proteinFamily.contains(candidateCategory) {
            return 6.0
        }

        if fruitFamily.contains(originalCategory) && fruitFamily.contains(candidateCategory) {
            return 5.0
        }

        return 0.0
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

        return caloriesRelative * 40
            + proteinRelative * 30
            + fatRelative * 15
            + carbsRelative * 15
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
            "seafood",
            "egg",
            "dairy",
            "grain",
            "legume",
            "vegetable",
            "fruit",
            "nut",
            "seed",
            "vegan",
            "high_protein"
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
        categoryBonus: Double,
        tagBonus: Double,
        ironDelta: Double?
    ) -> Double {
        var score = 100.0 - weightedPenalty + categoryBonus + tagBonus

        if let ironDelta {
            score += max(min(ironDelta * 2.5, 5.0), -5.0)
        }

        return min(max(score, 0), 100)
    }

    private static func macroGapMagnitude(_ delta: Macros) -> Double {
        abs(delta.calories) * 0.35
            + abs(delta.protein) * 0.30
            + abs(delta.fat) * 0.20
            + abs(delta.carbs) * 0.15
    }

    private static func normalizeText(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
