import SwiftUI

struct RecipeDetailView: View {
    let mealId: UUID
    @ObservedObject var vm: PlanViewModel

    @State private var pickedIndex: Int? = nil

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

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard(for: meal)

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
                        Text("This meal is already present in the diary. If you changed ingredients, use this action to refresh the diary entry.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                SectionTitleView(
                    "Ingredients",
                    subtitle: "Tap any ingredient to open smart substitutions with close nutritional match."
                )

                VStack(spacing: 12) {
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
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

                Text("Open ingredient substitutions to keep the meal flexible without losing the overall nutritional direction.")
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
