import Foundation
import Combine

@MainActor
final class PlanViewModel: ObservableObject {
    @Published var dayPlan: DayPlan = .empty {
        didSet { persistSession() }
    }

    @Published var diaryDay: DiaryDay = .empty {
        didSet { persistSession() }
    }

    private let foodRepo: FoodRepository
    private let recipeRepo: RecipeRepository
    private let sessionStore: PlanSessionStore

    private var excludedAllergens: Set<String> = []
    private var requiredTags: Set<String> = []
    private var allRecipes: [Recipe] = []
    private var currentGoal: NutritionGoal?
    private var currentNutrientFocus: NutrientFocus = .none

    private var hasConfiguredSession = false
    private var currentInputSignature: PlanInputSignature?

    init(
        foodRepo: FoodRepository = InMemoryFoodRepository(),
        recipeRepo: RecipeRepository = InMemoryRecipeRepository(),
        sessionStore: PlanSessionStore = UserDefaultsPlanSessionStore()
    ) {
        self.foodRepo = foodRepo
        self.recipeRepo = recipeRepo
        self.sessionStore = sessionStore
        self.allRecipes = recipeRepo.getAllRecipes()
    }

    var foodsById: [String: Food] {
        foodRepo.getFoodsById()
    }

    func configureSession(profile: UserProfile?, goal: NutritionGoal?) {
        excludedAllergens = Set(profile?.excludedAllergens.map(normalizeText) ?? [])
        currentNutrientFocus = profile?.nutrientFocus ?? .none
        currentGoal = goal

        let newSignature = buildInputSignature(profile: profile, goal: goal)

        if !hasConfiguredSession {
            hasConfiguredSession = true

            if let persisted = sessionStore.load(),
               persisted.inputSignature == newSignature {
                currentInputSignature = persisted.inputSignature
                dayPlan = persisted.dayPlan
                diaryDay = persisted.diaryDay
                return
            }
        }

        if currentInputSignature != newSignature {
            currentInputSignature = newSignature
            rebuildDayPlan(goal: goal)
            return
        }

        if dayPlan.meals.isEmpty {
            rebuildDayPlan(goal: goal)
        }
    }

    func resetSession() {
        currentInputSignature = nil
        dayPlan = .empty
        diaryDay = .empty
        sessionStore.clear()
    }

    func rebuildDayPlan(goal: NutritionGoal?) {
        currentGoal = goal

        dayPlan = MealPlanBuilder.buildDayPlan(
            goal: goal,
            recipes: allRecipes,
            foodsById: foodsById,
            excludedAllergens: excludedAllergens,
            nutrientFocus: currentNutrientFocus
        )
    }

    func meal(with id: UUID) -> PlannedMeal? {
        dayPlan.meals.first(where: { $0.id == id })
    }

    func summary(for recipe: Recipe) -> NutritionSummary {
        NutritionCalculator.summarize(
            ingredients: recipe.ingredients,
            foodsById: foodsById
        )
    }

    func daySummary() -> NutritionSummary {
        var totalMacros = Macros.zero
        var totalNutrients: [String: Double] = [:]

        for meal in dayPlan.meals {
            let mealSummary = summary(for: meal.recipe)
            totalMacros = totalMacros + mealSummary.macros

            for (key, value) in mealSummary.nutrients {
                totalNutrients[key, default: 0] += value
            }
        }

        return NutritionSummary(
            macros: totalMacros,
            nutrients: totalNutrients
        )
    }

    func actualSummary() -> NutritionSummary {
        var totalMacros = Macros.zero
        var totalNutrients: [String: Double] = [:]

        for entry in diaryDay.entries {
            let entrySummary = summary(for: entry.recipe)
            totalMacros = totalMacros + entrySummary.macros

            for (key, value) in entrySummary.nutrients {
                totalNutrients[key, default: 0] += value
            }
        }

        return NutritionSummary(
            macros: totalMacros,
            nutrients: totalNutrients
        )
    }

    func comparison() -> PlanComparison {
        PlanComparisonService.compare(
            planned: daySummary(),
            actual: actualSummary()
        )
    }

    func adjustmentRecommendation() -> PlanAdjustment? {
        guard let currentGoal else { return nil }
        guard !diaryDay.entries.isEmpty else { return nil }

        return PlanAdjuster.recommend(
            baseGoal: currentGoal,
            actual: actualSummary()
        )
    }

    func recipeIronAmount(for recipe: Recipe) -> Double {
        summary(for: recipe).nutrients["iron", default: 0]
    }

    func foodName(for id: String) -> String {
        let raw = foodsById[id]?.name ?? id
        return shortenFoodName(raw)
    }

    func displayTitle(for recipe: Recipe) -> String {
        guard recipe.isModified else { return recipe.name }

        let items: [TitleItem] = recipe.ingredients.compactMap { ing in
            guard let food = foodsById[ing.foodId] else { return nil }

            let factor = ing.grams / 100.0
            let calories = food.macrosPer100g.calories * factor

            return TitleItem(
                foodId: ing.foodId,
                name: shortenFoodName(food.name),
                grams: ing.grams,
                calories: calories,
                category: category(for: food)
            )
        }

        let suffix = dishSuffix(for: recipe)

        if let protein = items
            .filter({ $0.category == .protein })
            .max(by: { $0.calories < $1.calories }),
           let carb = items
            .filter({ $0.category == .carb })
            .max(by: { $0.calories < $1.calories }) {
            return "\(protein.name) + \(carb.name) \(suffix)"
        }

        let top = items
            .sorted { $0.calories > $1.calories }
            .prefix(2)
            .map { $0.name }

        if top.count == 2 {
            return "\(top[0]) + \(top[1]) \(suffix)"
        }

        return recipe.name
    }

    func substitutionCandidates(for ingredient: RecipeIngredient) -> [SubstitutionCandidate] {
        SubstitutionEngine.suggest(
            originalFoodId: ingredient.foodId,
            grams: ingredient.grams,
            foods: foodRepo.getAllFoods(),
            foodsById: foodsById,
            excludedAllergens: excludedAllergens,
            requiredTags: requiredTags
        )
    }

    func applySubstitution(mealId: UUID, ingredientIndex: Int, newFoodId: String) {
        guard let mealIndex = dayPlan.meals.firstIndex(where: { $0.id == mealId }) else {
            return
        }

        guard dayPlan.meals[mealIndex].recipe.ingredients.indices.contains(ingredientIndex) else {
            return
        }

        var updatedMeals = dayPlan.meals
        let oldIngredient = updatedMeals[mealIndex].recipe.ingredients[ingredientIndex]

        guard oldIngredient.foodId != newFoodId else {
            return
        }

        updatedMeals[mealIndex].recipe.ingredients[ingredientIndex] = RecipeIngredient(
            foodId: newFoodId,
            grams: oldIngredient.grams
        )
        updatedMeals[mealIndex].recipe.isModified = true

        dayPlan = DayPlan(meals: updatedMeals)

        if let diaryIndex = diaryDay.entries.firstIndex(where: { $0.mealId == mealId }),
           let updatedMeal = meal(with: mealId) {
            var updatedEntries = diaryDay.entries
            updatedEntries[diaryIndex].recipe = updatedMeal.recipe
            updatedEntries[diaryIndex].title = displayTitle(for: updatedMeal.recipe)
            diaryDay = DiaryDay(entries: sortedDiaryEntries(updatedEntries))
        }
    }

    func isMealLogged(_ mealId: UUID) -> Bool {
        diaryDay.entries.contains(where: { $0.mealId == mealId })
    }

    func addMealToDiary(mealId: UUID) {
        guard let meal = meal(with: mealId) else { return }

        var updatedEntries = diaryDay.entries
        let title = displayTitle(for: meal.recipe)

        if let existingIndex = updatedEntries.firstIndex(where: { $0.mealId == mealId }) {
            updatedEntries[existingIndex].title = title
            updatedEntries[existingIndex].recipe = meal.recipe
        } else {
            updatedEntries.append(
                ConsumedFoodEntry(
                    mealId: meal.id,
                    mealType: meal.type,
                    title: title,
                    recipe: meal.recipe
                )
            )
        }

        diaryDay = DiaryDay(entries: sortedDiaryEntries(updatedEntries))
    }

    func removeDiaryEntry(id: UUID) {
        diaryDay.entries.removeAll { $0.id == id }
    }

    func clearDiary() {
        diaryDay = .empty
    }

    private func persistSession() {
        guard let currentInputSignature else { return }

        sessionStore.save(
            inputSignature: currentInputSignature,
            dayPlan: dayPlan,
            diaryDay: diaryDay
        )
    }

    private func buildInputSignature(
        profile: UserProfile?,
        goal: NutritionGoal?
    ) -> PlanInputSignature {
        PlanInputSignature(
            sex: profile?.sex,
            age: profile?.age,
            heightCm: profile.map { Int($0.heightCm.rounded()) },
            weightKg: profile.map { Int($0.weightKg.rounded()) },
            activityLevel: profile?.activityLevel,
            goalType: profile?.goalType,
            nutrientFocus: profile?.nutrientFocus,
            excludedAllergens: (profile?.excludedAllergens ?? [])
                .map(normalizeText)
                .sorted(),
            excludedProducts: (profile?.excludedProducts ?? [])
                .map(normalizeText)
                .sorted(),
            targetCalories: goal?.targetCalories,
            proteinGrams: goal?.proteinGrams,
            fatGrams: goal?.fatGrams,
            carbsGrams: goal?.carbsGrams
        )
    }

    private func normalizeText(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func sortedDiaryEntries(_ entries: [ConsumedFoodEntry]) -> [ConsumedFoodEntry] {
        entries.sorted {
            if mealTypeOrder($0.mealType) != mealTypeOrder($1.mealType) {
                return mealTypeOrder($0.mealType) < mealTypeOrder($1.mealType)
            }

            return $0.loggedAt < $1.loggedAt
        }
    }

    private func mealTypeOrder(_ mealType: MealType) -> Int {
        switch mealType {
        case .breakfast:
            return 0
        case .lunch:
            return 1
        case .dinner:
            return 2
        case .snack:
            return 3
        }
    }

    private func dishSuffix(for recipe: Recipe) -> String {
        if recipe.tags.contains("salad") { return "Salad" }
        if recipe.tags.contains("plate") { return "Plate" }
        if recipe.tags.contains("bowl") { return "Bowl" }
        return "Bowl"
    }

    private enum TitleCategory {
        case protein
        case carb
        case veggie
        case other
    }

    private func category(for food: Food) -> TitleCategory {
        if food.tags.contains("meat") {
            return .protein
        }

        if food.tags.contains("grain") || food.tags.contains("legume") {
            return .carb
        }

        if food.tags.contains("vegetable") {
            return .veggie
        }

        return .other
    }

    private struct TitleItem {
        let foodId: String
        let name: String
        let grams: Double
        let calories: Double
        let category: TitleCategory
    }

    private func shortenFoodName(_ name: String) -> String {
        let result = name.replacingOccurrences(
            of: #"\s*\([^)]*\)"#,
            with: "",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
