import Foundation
import Combine

@MainActor
final class PlanViewModel: ObservableObject {
    @Published var dayPlan: DayPlan = .empty {
        didSet {
            pruneCheckedShoppingItemsIfNeeded()
            persistSession()
        }
    }

    @Published var diaryDay: DiaryDay = .empty {
        didSet {
            persistSession()
        }
    }

    @Published private(set) var checkedShoppingItemIds: Set<String> = [] {
        didSet {
            persistSession()
        }
    }

    @Published private(set) var selectedDayId: String = DayIdentifier.current()
    @Published private(set) var isCloudRestoreInProgress = false
    @Published private(set) var lastCloudRestoreAt: Date?
    @Published var cloudRestoreMessage: String?

    private let accountId: String?
    private let foodRepo: FoodRepository
    private let recipeRepo: RecipeRepository
    private let sessionStore: PlanSessionStore
    private let remoteDayStore: DayRecordsRemoteStore?

    private var excludedAllergens: Set<String> = []
    private var excludedProducts: Set<String> = []
    private var excludedGroups: Set<String> = []
    private var requiredTags: Set<String> = []
    private var allRecipes: [Recipe] = []
    private var currentGoal: NutritionGoal?
    private var currentNutrientFocus: NutrientFocus = .none

    private var hasConfiguredSession = false
    private var hasStartedRemoteSync = false
    private var currentInputSignature: PlanInputSignature?
    private var remoteHistoryRecords: [PlanHistoryRecord] = []

    init(
        accountId: String? = nil,
        foodRepo: FoodRepository = InMemoryFoodRepository(),
        recipeRepo: RecipeRepository = InMemoryRecipeRepository(),
        sessionStore: PlanSessionStore = UserDefaultsPlanSessionStore(accountId: "local_guest"),
        remoteDayStore: DayRecordsRemoteStore? = nil
    ) {
        self.accountId = accountId
        self.foodRepo = foodRepo
        self.recipeRepo = recipeRepo
        self.sessionStore = sessionStore
        self.remoteDayStore = remoteDayStore
        self.allRecipes = recipeRepo.getAllRecipes()
    }

    var foodsById: [String: Food] {
        foodRepo.getFoodsById()
    }

    var allFoods: [Food] {
        foodRepo
            .getAllFoods()
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    var shoppingItems: [ShoppingItem] {
        ShoppingListBuilder.build(
            recipes: dayPlan.meals.map(\.recipe),
            foodsById: foodsById
        )
    }

    func configureSession(profile: UserProfile?, goal: NutritionGoal?) {
        selectedDayId = DayIdentifier.current()

        excludedAllergens = Set(profile?.excludedAllergens.map(normalizeText) ?? [])
        excludedProducts = Set(profile?.excludedProducts.map(normalizeText) ?? [])
        excludedGroups = Set(profile?.excludedGroups.map(normalizeText) ?? [])
        currentNutrientFocus = profile?.nutrientFocus ?? .none
        currentGoal = goal

        let newSignature = buildInputSignature(profile: profile, goal: goal)

        if !hasConfiguredSession {
            hasConfiguredSession = true
            archiveStaleSessionIfNeeded()

            if let persisted = sessionStore.loadCurrentDay(),
               persisted.dayId == selectedDayId,
               persisted.inputSignature == newSignature {
                currentInputSignature = persisted.inputSignature
                dayPlan = persisted.dayPlan
                diaryDay = persisted.diaryDay
                checkedShoppingItemIds = Set(persisted.checkedShoppingItemIds)
                pruneCheckedShoppingItemsIfNeeded()
                persistSession()
                startRemoteSyncIfNeeded()
                return
            }
        }

        if currentInputSignature != newSignature {
            currentInputSignature = newSignature
            checkedShoppingItemIds = []
            rebuildDayPlan(goal: goal)
            startRemoteSyncIfNeeded()
            return
        }

        if dayPlan.meals.isEmpty {
            rebuildDayPlan(goal: goal)
        }

        startRemoteSyncIfNeeded()
    }

    func reloadCloudState() {
        performRemoteSync(showLoading: true)
    }

    func resetSession() {
        currentInputSignature = nil
        checkedShoppingItemIds = []
        dayPlan = .empty
        diaryDay = .empty
        sessionStore.clearCurrentDay()

        if let accountId, let remoteDayStore {
            Task {
                do {
                    try await remoteDayStore.clearCurrentDay(uid: accountId)
                } catch {
                    print("Failed to clear remote current day: \(error)")
                }
            }
        }
    }

    func rebuildDayPlan(goal: NutritionGoal?) {
        currentGoal = goal

        dayPlan = MealPlanBuilder.buildDayPlan(
            goal: goal,
            recipes: allRecipes,
            foodsById: foodsById,
            excludedAllergens: excludedAllergens,
            excludedProducts: excludedProducts,
            excludedGroups: excludedGroups,
            nutrientFocus: currentNutrientFocus
        )
    }

    func shuffleDayPlan(goal: NutritionGoal?) {
        currentGoal = goal

        let allowedRecipes = MealPlanBuilder.filteredAllowedRecipes(
            recipes: allRecipes,
            foodsById: foodsById,
            excludedAllergens: excludedAllergens,
            excludedProducts: excludedProducts,
            excludedGroups: excludedGroups
        )

        let candidatePools = MealPlanBuilder.buildCandidatePools(
            goal: goal,
            recipes: allowedRecipes,
            foodsById: foodsById,
            nutrientFocus: currentNutrientFocus
        )

        let rankedOptions = DayPlanShuffleService.buildRankedOptions(
            goal: goal,
            candidatePools: candidatePools,
            foodsById: foodsById,
            nutrientFocus: currentNutrientFocus,
            maxOptions: 16
        )

        guard let selected = DayPlanShuffleService.shuffledOption(
            from: rankedOptions,
            currentMeals: dayPlan.meals
        ) else {
            rebuildDayPlan(goal: goal)
            return
        }

        let rawPlan = DayPlan(meals: selected.meals)

        dayPlan = MealPlanBuilder.finalizeDayPlan(
            rawPlan,
            goal: goal,
            allowedRecipes: allowedRecipes,
            foodsById: foodsById,
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

    func recipeSelectionBreakdown(
        for recipe: Recipe,
        mealType: MealType
    ) -> RecipeScoreBreakdown {
        RecipeScorer.evaluate(
            recipe: recipe,
            mealType: mealType,
            goal: currentGoal,
            foodsById: foodsById,
            nutrientFocus: currentNutrientFocus
        )
    }

    func foodName(for id: String) -> String {
        let raw = foodsById[id]?.name ?? id
        return shortenFoodName(raw)
    }

    func displayTitle(for recipe: Recipe) -> String {
        guard recipe.isModified else { return recipe.name }

        let items: [TitleItem] = recipe.ingredients.compactMap { ingredient in
            guard let food = foodsById[ingredient.foodId] else { return nil }

            let factor = ingredient.grams / 100.0
            let calories = food.macrosPer100g.calories * factor

            return TitleItem(
                name: shortenFoodName(food.name),
                calories: calories,
                category: category(for: food)
            )
        }

        let generatedTitle = composeModifiedRecipeTitle(from: items)

        if generatedTitle.isEmpty {
            return recipe.name
        }

        return generatedTitle
    }

    func substitutionCandidates(for ingredient: RecipeIngredient) -> [SubstitutionCandidate] {
        SubstitutionEngine.suggest(
            originalFoodId: ingredient.foodId,
            grams: ingredient.grams,
            foods: foodRepo.getAllFoods(),
            foodsById: foodsById,
            excludedAllergens: excludedAllergens,
            excludedProducts: excludedProducts,
            excludedGroups: excludedGroups,
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

        syncDiaryEntryIfNeeded(for: mealId)
    }

    func addManualFoodEntry(foodId: String, grams: Double, mealType: MealType) {
        guard let food = foodsById[foodId] else { return }

        let normalizedGrams = max(1, min(1500, grams))
        let manualRecipe = Recipe(
            id: "manual-\(UUID().uuidString)",
            name: shortenFoodName(food.name),
            ingredients: [
                RecipeIngredient(
                    foodId: foodId,
                    grams: normalizedGrams
                )
            ],
            cookTimeMinutes: nil,
            tags: [],
            isModified: true
        )

        let title = "\(shortenFoodName(food.name)) — \(gramsText(normalizedGrams))"

        var updatedEntries = diaryDay.entries
        updatedEntries.append(
            ConsumedFoodEntry(
                mealId: nil,
                mealType: mealType,
                title: title,
                recipe: manualRecipe
            )
        )

        diaryDay = DiaryDay(entries: sortedDiaryEntries(updatedEntries))
    }

    private func syncDiaryEntryIfNeeded(for mealId: UUID) {
        guard let diaryIndex = diaryDay.entries.firstIndex(where: { $0.mealId == mealId }),
              let updatedMeal = meal(with: mealId) else {
            return
        }

        var updatedEntries = diaryDay.entries
        updatedEntries[diaryIndex].recipe = updatedMeal.recipe
        updatedEntries[diaryIndex].title = displayTitle(for: updatedMeal.recipe)
        diaryDay = DiaryDay(entries: sortedDiaryEntries(updatedEntries))
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

    func isShoppingItemChecked(_ id: String) -> Bool {
        checkedShoppingItemIds.contains(id)
    }

    func toggleShoppingItemChecked(_ id: String) {
        if checkedShoppingItemIds.contains(id) {
            checkedShoppingItemIds.remove(id)
        } else {
            checkedShoppingItemIds.insert(id)
        }
    }

    func clearCheckedShoppingItems() {
        checkedShoppingItemIds = []
    }

    func historyRecords() -> [PlanHistoryRecord] {
        mergeHistoryRecords(
            local: sessionStore.loadHistory(),
            remote: remoteHistoryRecords
        )
    }

    private func startRemoteSyncIfNeeded() {
        guard !hasStartedRemoteSync else { return }
        hasStartedRemoteSync = true
        performRemoteSync(showLoading: false)
    }

    private func performRemoteSync(showLoading: Bool) {
        guard let accountId, let remoteDayStore else { return }

        if showLoading {
            cloudRestoreMessage = nil
            isCloudRestoreInProgress = true
        }

        Task {
            do {
                async let currentTask = remoteDayStore.fetchCurrentDay(uid: accountId)
                async let historyTask = remoteDayStore.fetchHistory(uid: accountId)

                let (remoteCurrent, remoteHistory) = try await (currentTask, historyTask)

                await MainActor.run {
                    self.remoteHistoryRecords = remoteHistory.sorted { $0.dayId > $1.dayId }
                    self.applyRemoteCurrentIfNeeded(remoteCurrent)
                    self.lastCloudRestoreAt = Date()

                    if showLoading {
                        self.cloudRestoreMessage = "Текущий день и архив обновлены из облака."
                        self.isCloudRestoreInProgress = false
                    }
                }
            } catch {
                await MainActor.run {
                    if showLoading {
                        self.cloudRestoreMessage = "Не удалось обновить день и архив из облака: \(error.localizedDescription)"
                        self.isCloudRestoreInProgress = false
                    } else {
                        print("Failed to sync remote day data: \(error)")
                    }
                }
            }
        }
    }

    private func applyRemoteCurrentIfNeeded(_ remoteSession: PersistedPlanSession?) {
        guard let remoteSession else { return }
        guard remoteSession.dayId == selectedDayId else { return }
        guard remoteSession.inputSignature == currentInputSignature else { return }

        let localSession = sessionStore.loadCurrentDay()
        let shouldUseRemote: Bool

        if let localSession {
            shouldUseRemote = remoteSession.savedAt > localSession.savedAt
        } else {
            shouldUseRemote = true
        }

        guard shouldUseRemote else { return }

        currentInputSignature = remoteSession.inputSignature
        dayPlan = remoteSession.dayPlan
        diaryDay = remoteSession.diaryDay
        checkedShoppingItemIds = Set(remoteSession.checkedShoppingItemIds)
        pruneCheckedShoppingItemsIfNeeded()
    }

    private func archiveStaleSessionIfNeeded() {
        guard let persisted = sessionStore.loadCurrentDay() else { return }
        guard persisted.dayId != selectedDayId else { return }

        let record = PlanHistoryRecord(from: persisted)

        sessionStore.appendHistoryRecord(from: persisted)
        sessionStore.clearCurrentDay()
        upsertRemoteHistoryRecord(record)

        if let accountId, let remoteDayStore {
            Task {
                do {
                    try await remoteDayStore.saveHistoryRecord(record, uid: accountId)
                    try await remoteDayStore.clearCurrentDay(uid: accountId)
                } catch {
                    print("Failed to archive remote current day: \(error)")
                }
            }
        }
    }

    private func persistSession() {
        guard let currentInputSignature else { return }

        let session = PersistedPlanSession(
            dayId: selectedDayId,
            savedAt: Date(),
            inputSignature: currentInputSignature,
            dayPlan: dayPlan,
            diaryDay: diaryDay,
            checkedShoppingItemIds: checkedShoppingItemIds.sorted()
        )

        sessionStore.saveCurrentDay(
            dayId: selectedDayId,
            inputSignature: currentInputSignature,
            dayPlan: dayPlan,
            diaryDay: diaryDay,
            checkedShoppingItemIds: checkedShoppingItemIds
        )

        guard let accountId, let remoteDayStore else { return }

        Task {
            do {
                try await remoteDayStore.saveCurrentDay(session, uid: accountId)
            } catch {
                print("Failed to save remote current day: \(error)")
            }
        }
    }

    private func pruneCheckedShoppingItemsIfNeeded() {
        let availableIds = Set(shoppingItems.map(\.id))
        let filtered = checkedShoppingItemIds.intersection(availableIds)

        if filtered != checkedShoppingItemIds {
            checkedShoppingItemIds = filtered
        }
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
            excludedGroups: (profile?.excludedGroups ?? [])
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

    private func mergeHistoryRecords(
        local: [PlanHistoryRecord],
        remote: [PlanHistoryRecord]
    ) -> [PlanHistoryRecord] {
        var bestByDayId: [String: PlanHistoryRecord] = [:]

        for record in local + remote {
            if let existing = bestByDayId[record.dayId] {
                if record.savedAt > existing.savedAt {
                    bestByDayId[record.dayId] = record
                }
            } else {
                bestByDayId[record.dayId] = record
            }
        }

        return bestByDayId.values.sorted { $0.dayId > $1.dayId }
    }

    private func upsertRemoteHistoryRecord(_ record: PlanHistoryRecord) {
        remoteHistoryRecords.removeAll { $0.dayId == record.dayId }
        remoteHistoryRecords.append(record)
        remoteHistoryRecords.sort { $0.dayId > $1.dayId }
    }

    private enum TitleCategory {
        case protein
        case carb
        case veggie
        case fruit
        case dairy
        case other
    }

    private func category(for food: Food) -> TitleCategory {
        if food.tags.contains("meat")
            || food.tags.contains("egg")
            || food.tags.contains("seafood")
            || food.groups.contains("poultry")
            || food.groups.contains("seafood")
            || food.groups.contains("red_meat")
            || food.groups.contains("eggs")
            || food.groups.contains("protein_alt") {
            return .protein
        }

        if food.tags.contains("grain")
            || food.tags.contains("legume")
            || food.groups.contains("grain")
            || food.groups.contains("legumes") {
            return .carb
        }

        if food.tags.contains("vegetable")
            || food.groups.contains("vegetable") {
            return .veggie
        }

        if food.tags.contains("fruit")
            || food.groups.contains("fruit")
            || food.groups.contains("berries")
            || food.groups.contains("citrus") {
            return .fruit
        }

        if food.groups.contains("dairy") {
            return .dairy
        }

        return .other
    }

    private struct TitleItem {
        let name: String
        let calories: Double
        let category: TitleCategory
    }

    private func composeModifiedRecipeTitle(from items: [TitleItem]) -> String {
        guard !items.isEmpty else { return "" }

        var orderedNames: [String] = []

        func appendTopName(for category: TitleCategory) {
            if let candidate = items
                .filter({ $0.category == category })
                .sorted(by: { $0.calories > $1.calories })
                .first?.name,
               !orderedNames.contains(candidate) {
                orderedNames.append(candidate)
            }
        }

        appendTopName(for: .protein)
        appendTopName(for: .carb)
        appendTopName(for: .veggie)
        appendTopName(for: .fruit)
        appendTopName(for: .dairy)

        let fallbackNames = items
            .sorted { $0.calories > $1.calories }
            .map(\.name)

        for name in fallbackNames where !orderedNames.contains(name) {
            orderedNames.append(name)
        }

        let visibleNames = Array(orderedNames.prefix(3))

        switch visibleNames.count {
        case 0:
            return ""
        case 1:
            return visibleNames[0]
        case 2:
            return "\(visibleNames[0]) + \(visibleNames[1])"
        default:
            return "\(visibleNames[0]) + \(visibleNames[1]) + \(visibleNames[2])"
        }
    }

    private func shortenFoodName(_ name: String) -> String {
        var result = name

        result = result.replacingOccurrences(
            of: #"\s*\([^)]*\)"#,
            with: "",
            options: .regularExpression
        )

        let fragmentsToRemove = [
            " cooked",
            " boiled",
            " raw",
            " fresh",
            " steamed",
            " roasted",
            "запечённый",
            "запеченная",
            "запеченное",
            "запечённая",
            "запечённое",
            "варёный",
            "вареный",
            "варёная",
            "вареная",
            "отварной",
            "отварная",
            "сухой",
            "сухая"
        ]

        for fragment in fragmentsToRemove {
            result = result.replacingOccurrences(
                of: fragment,
                with: "",
                options: .caseInsensitive
            )
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func gramsText(_ grams: Double) -> String {
        if abs(grams.rounded() - grams) < 0.001 {
            return "\(Int(grams.rounded())) г"
        }

        return String(format: "%.0f г", grams)
    }
}
