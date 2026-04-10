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
                    "Why this recipe was selected",
                    subtitle: "The planner estimates how well the recipe matches the target for this meal."
                )

                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Selection score")
                                .font(.headline)

                            Spacer()

                            StatPill(text: "\(Int(scoreBreakdown.totalScore.rounded())) / 100")
                        }

                        Text(selectionSummary(for: scoreBreakdown))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Divider()

                        InfoValueRow(
                            title: "Target calories",
                            value: "\(Int(scoreBreakdown.mealTargetCalories.rounded())) kcal"
                        )
                        InfoValueRow(
                            title: "Recipe calories",
                            value: "\(Int(scoreBreakdown.actualCalories.rounded())) kcal"
                        )

                        InfoValueRow(
                            title: "Target protein",
                            value: String(format: "%.1f g", scoreBreakdown.mealTargetProtein)
                        )
                        InfoValueRow(
                            title: "Recipe protein",
                            value: String(format: "%.1f g", scoreBreakdown.actualProtein)
                        )

                        InfoValueRow(
                            title: "Penalty",
                            value: String(
                                format: "%.1f",
                                scoreBreakdown.caloriePenalty
                                + scoreBreakdown.proteinPenalty
                                + scoreBreakdown.fatPenalty
                                + scoreBreakdown.carbsPenalty
                            )
                        )

                        if scoreBreakdown.nutrientBonus > 0 {
                            InfoValueRow(
                                title: "Micronutrient bonus",
                                value: String(format: "+%.1f", scoreBreakdown.nutrientBonus)
                            )
                        }

                        if scoreBreakdown.tagBonus > 0 {
                            InfoValueRow(
                                title: "Meal tag bonus",
                                value: String(format: "+%.1f", scoreBreakdown.tagBonus)
                            )
                        }

                        if scoreBreakdown.ironAmount > 0 {
                            InfoValueRow(
                                title: "Iron",
                                value: String(format: "%.2f mg", scoreBreakdown.ironAmount)
                            )
                        }
                    }
                }

                SectionTitleView(
                    "Recipe summary",
                    subtitle: "Nutrition values for the current version of this meal."
                )

                AppCard {
                    RecipeSummaryGrid(
                        caloriesText: "\(Int(summary.macros.calories)) kcal",
                        proteinText: String(format: "%.1f g", summary.macros.protein),
                        fatText: String(format: "%.1f g", summary.macros.fat),
                        carbsText: String(format: "%.1f g", summary.macros.carbs),
                        ironText: iron.map { String(format: "%.2f mg", $0) }
                    )
                }

                SectionTitleView(
                    "Actions",
                    subtitle: "Add the meal to diary or update the existing diary entry."
                )

                AppCard {
                    Button {
                        vm.addMealToDiary(mealId: mealId)
                    } label: {
                        HStack {
                            Image(systemName: vm.isMealLogged(mealId) ? "arrow.trianglehead.clockwise" : "plus.circle.fill")
                                .font(.title3)

                            Text(vm.isMealLogged(mealId) ? "Update diary entry" : "Add to diary")
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
                        Text("If you changed ingredients or portion size, use this action to refresh the diary entry.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                SectionTitleView(
                    "Ingredients and portion tuning",
                    subtitle: "Tap an ingredient to replace it, or change its weight by a fixed step of 25 g."
                )

                VStack(spacing: 12) {
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                        VStack(spacing: 10) {
                            RecipeIngredientCard(
                                title: vm.foodName(for: ingredient.foodId),
                                gramsText: "\(Int(ingredient.grams)) g",
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
                Text("Ingredient not found")
                    .padding()
            }
        }
    }

    private var unavailableState: some View {
        VStack(spacing: 12) {
            Text("Meal not found")
                .font(.headline)

            Text("This meal is no longer available.")
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
                    StatPill(text: meal.type.rawValue)

                    if recipe.isModified {
                        StatPill(text: "Modified")
                    }

                    if vm.isMealLogged(mealId) {
                        StatPill(text: "In diary")
                    }
                }

                Text(vm.displayTitle(for: recipe))
                    .font(.title2.weight(.bold))

                Text("The meal is selected by a recipe score that considers target calories, macros and micronutrient focus.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let cookTimeMinutes = recipe.cookTimeMinutes {
                    Divider()

                    InfoValueRow(
                        title: "Cook time",
                        value: "\(cookTimeMinutes) min"
                    )
                }
            }
        }
    }

    private func selectionSummary(for breakdown: RecipeScoreBreakdown) -> String {
        if breakdown.totalScore >= 90 {
            return "This recipe is very close to the target values for the current meal."
        } else if breakdown.totalScore >= 75 {
            return "This recipe is a good match with moderate deviation from the target."
        } else {
            return "This recipe is acceptable, but it deviates more noticeably from the target values."
        }
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
        return String(format: "%.2f mg", iron)
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
