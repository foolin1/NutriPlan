import SwiftUI

struct RecipeDetailView: View {
    let mealId: UUID
    @ObservedObject var vm: PlanViewModel

    @State private var pickedIndex: Int? = nil

    private let portionStep: Double = 25
    private let minIngredientGrams: Double = 25
    private let maxIngredientGrams: Double = 500

    var body: some View {
        Group {
            if let meal = vm.meal(with: mealId) {
                content(for: meal)
            } else {
                unavailableState
            }
        }
    }

    @ViewBuilder
    private func content(for meal: PlannedMeal) -> some View {
        let recipe = meal.recipe
        let summary = vm.summary(for: recipe)
        let iron = summary.nutrients["iron"]
        let scoreBreakdown = vm.recipeSelectionBreakdown(
            for: recipe,
            mealType: meal.type
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard(for: meal)

                SectionTitleView(
                    "Почему выбрано это блюдо",
                    subtitle: "Краткое объяснение, насколько блюдо подходит под текущую цель."
                )

                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Оценка выбора")
                                .font(.headline)

                            Spacer()

                            StatPill(text: "\(Int(scoreBreakdown.totalScore.rounded())) / 100")
                        }

                        Text(selectionSummary(for: scoreBreakdown))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if !selectionHighlights(for: scoreBreakdown).isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(selectionHighlights(for: scoreBreakdown), id: \.self) { item in
                                    Text("• \(item)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Divider()

                        InfoValueRow(
                            title: "Целевые калории",
                            value: "\(Int(scoreBreakdown.mealTargetCalories.rounded())) ккал"
                        )
                        InfoValueRow(
                            title: "Калории блюда",
                            value: "\(Int(scoreBreakdown.actualCalories.rounded())) ккал"
                        )

                        InfoValueRow(
                            title: "Целевые белки",
                            value: String(format: "%.1f г", scoreBreakdown.mealTargetProtein)
                        )
                        InfoValueRow(
                            title: "Белки блюда",
                            value: String(format: "%.1f г", scoreBreakdown.actualProtein)
                        )

                        if scoreBreakdown.ironAmount > 0 {
                            InfoValueRow(
                                title: "Железо",
                                value: String(format: "%.2f мг", scoreBreakdown.ironAmount)
                            )
                        }
                    }
                }

                SectionTitleView(
                    "Сводка по рецепту",
                    subtitle: "Пищевые показатели для текущей версии блюда."
                )

                AppCard {
                    RecipeSummaryGrid(
                        caloriesText: "\(Int(summary.macros.calories)) ккал",
                        proteinText: String(format: "%.1f г", summary.macros.protein),
                        fatText: String(format: "%.1f г", summary.macros.fat),
                        carbsText: String(format: "%.1f г", summary.macros.carbs),
                        ironText: iron.map { String(format: "%.2f мг", $0) }
                    )
                }

                SectionTitleView(
                    "Действия",
                    subtitle: "Добавь блюдо в дневник или обнови существующую запись."
                )

                AppCard {
                    Button {
                        vm.addMealToDiary(mealId: mealId)
                    } label: {
                        HStack {
                            Image(systemName: vm.isMealLogged(mealId) ? "arrow.trianglehead.clockwise" : "plus.circle.fill")
                                .font(.title3)

                            Text(vm.isMealLogged(mealId) ? "Обновить запись в дневнике" : "Добавить в дневник")
                                .font(.headline)

                            Spacer()
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.accentColor.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)

                    if vm.isMealLogged(mealId) {
                        Text("Если ты изменил ингредиенты или вес порции, используй это действие, чтобы обновить запись в дневнике.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                SectionTitleView(
                    "Ингредиенты и настройка порции",
                    subtitle: "Нажми на ингредиент, чтобы заменить его, или измени вес с шагом 25 г."
                )

                VStack(spacing: 12) {
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                        VStack(spacing: 10) {
                            RecipeIngredientCard(
                                title: vm.foodName(for: ingredient.foodId),
                                gramsText: "\(Int(ingredient.grams)) г",
                                caloriesText: "\(Int(ingredientMacros(for: ingredient).calories))",
                                proteinText: String(format: "%.1f", ingredientMacros(for: ingredient).protein),
                                fatText: String(format: "%.1f", ingredientMacros(for: ingredient).fat),
                                carbsText: String(format: "%.1f", ingredientMacros(for: ingredient).carbs),
                                ironText: ingredientIronText(for: ingredient)
                            ) {
                                pickedIndex = index
                            }

                            IngredientPortionControl(
                                grams: ingredient.grams,
                                step: portionStep,
                                canDecrease: ingredient.grams > minIngredientGrams,
                                canIncrease: ingredient.grams < maxIngredientGrams,
                                onDecrease: {
                                    vm.decreaseIngredientPortion(
                                        mealId: mealId,
                                        ingredientIndex: index,
                                        step: portionStep,
                                        minGrams: minIngredientGrams,
                                        maxGrams: maxIngredientGrams
                                    )
                                },
                                onIncrease: {
                                    vm.increaseIngredientPortion(
                                        mealId: mealId,
                                        ingredientIndex: index,
                                        step: portionStep,
                                        minGrams: minIngredientGrams,
                                        maxGrams: maxIngredientGrams
                                    )
                                }
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(vm.displayTitle(for: recipe))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $pickedIndex.asIdentifiable) { wrapped in
            let idx = wrapped.value

            if let currentMeal = vm.meal(with: mealId),
               currentMeal.recipe.ingredients.indices.contains(idx) {
                let ingredient = currentMeal.recipe.ingredients[idx]
                let originalName = vm.foodName(for: ingredient.foodId)
                let candidates = vm.substitutionCandidates(for: ingredient)

                SubstitutionPickerView(
                    originalName: originalName,
                    grams: ingredient.grams,
                    candidates: candidates
                ) { chosen in
                    vm.applySubstitution(
                        mealId: mealId,
                        ingredientIndex: idx,
                        newFoodId: chosen.id
                    )
                }
            } else {
                Text("Ингредиент не найден")
                    .padding()
            }
        }
    }

    private var unavailableState: some View {
        VStack(spacing: 12) {
            Text("Блюдо не найдено")
                .font(.headline)

            Text("Это блюдо больше недоступно.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    @ViewBuilder
    private func headerCard(for meal: PlannedMeal) -> some View {
        let recipe = meal.recipe

        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StatPill(text: meal.type.ruTitle)

                    if recipe.isModified {
                        StatPill(text: "Изменено")
                    }

                    if vm.isMealLogged(mealId) {
                        StatPill(text: "В дневнике")
                    }
                }

                Text(vm.displayTitle(for: recipe))
                    .font(.title2.weight(.bold))

                Text("Блюдо подобрано с учётом цели по питанию, текущих ограничений и типа приёма пищи.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let cookTimeMinutes = recipe.cookTimeMinutes {
                    Divider()

                    InfoValueRow(
                        title: "Время приготовления",
                        value: "\(cookTimeMinutes) мин"
                    )
                }
            }
        }
    }

    private func selectionSummary(for breakdown: RecipeScoreBreakdown) -> String {
        if breakdown.totalScore >= 90 {
            return "Это блюдо очень хорошо соответствует цели для текущего приёма пищи."
        } else if breakdown.totalScore >= 75 {
            return "Это блюдо в целом хорошо подходит, но немного отклоняется от целевых параметров."
        } else {
            return "Это блюдо допустимо, но отклоняется от целевых значений заметнее."
        }
    }

    private func selectionHighlights(for breakdown: RecipeScoreBreakdown) -> [String] {
        var result: [String] = []

        let calorieGap = abs(breakdown.actualCalories - breakdown.mealTargetCalories)
        let proteinGap = breakdown.mealTargetProtein - breakdown.actualProtein

        if calorieGap <= 60 {
            result.append("Калорийность блюда близка к целевому значению.")
        } else if breakdown.actualCalories < breakdown.mealTargetCalories {
            result.append("Блюдо немного легче по калорийности, чем целевое значение.")
        } else {
            result.append("Блюдо немного калорийнее целевого значения.")
        }

        if proteinGap <= 0 {
            result.append("Содержание белка соответствует цели или выше неё.")
        } else if proteinGap <= 5 {
            result.append("Белка немного меньше целевого значения.")
        } else {
            result.append("Белка заметно меньше, чем желательно для этого приёма пищи.")
        }

        if breakdown.ironAmount >= 2 {
            result.append("Блюдо даёт полезный вклад в потребление железа.")
        }

        return result
    }

    private func ingredientMacros(for ingredient: RecipeIngredient) -> Macros {
        guard let food = vm.foodsById[ingredient.foodId] else {
            return .zero
        }

        let factor = ingredient.grams / 100.0
        return food.macrosPer100g * factor
    }

    private func ingredientIronText(for ingredient: RecipeIngredient) -> String? {
        guard let food = vm.foodsById[ingredient.foodId] else {
            return nil
        }

        let factor = ingredient.grams / 100.0
        let iron = food.nutrientsPer100g["iron", default: 0] * factor

        guard iron > 0 else { return nil }
        return String(format: "%.2f мг", iron)
    }
}

private struct IdentifiedInt: Identifiable {
    let id = UUID()
    let value: Int
}

private extension Binding where Value == Int? {
    var asIdentifiable: Binding<IdentifiedInt?> {
        Binding<IdentifiedInt?>(
            get: { wrappedValue.map { IdentifiedInt(value: $0) } },
            set: { wrappedValue = $0?.value }
        )
    }
}
