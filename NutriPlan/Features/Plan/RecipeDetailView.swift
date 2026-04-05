import SwiftUI

struct RecipeDetailView: View {

    let mealId: UUID
    @ObservedObject var vm: PlanViewModel

    @State private var pickedIndex: Int? = nil

    var body: some View {
        Group {
            if let meal = vm.meal(with: mealId) {
                let recipe = meal.recipe
                let summary = vm.summary(for: recipe)

                List {
                    Section("Summary") {
                        Text("Calories: \(Int(summary.macros.calories))")
                        Text("P: \(summary.macros.protein, specifier: "%.1f")  F: \(summary.macros.fat, specifier: "%.1f")  C: \(summary.macros.carbs, specifier: "%.1f")")
                        if let iron = summary.nutrients["iron"] {
                            Text("Iron: \(iron, specifier: "%.2f") mg")
                        }
                    }

                    Section("Actions") {
                        Button {
                            vm.addMealToDiary(mealId: mealId)
                        } label: {
                            Text(vm.isMealLogged(mealId) ? "Update diary entry" : "Add to diary")
                        }

                        if vm.isMealLogged(mealId) {
                            Text("This meal is already added to the diary.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Ingredients") {
                        ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ing in
                            Button {
                                pickedIndex = index
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(vm.foodName(for: ing.foodId))
                                        Text("\(Int(ing.grams)) g")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .navigationTitle(vm.displayTitle(for: recipe))
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
            } else {
                VStack(spacing: 12) {
                    Text("Meal not found")
                        .font(.headline)
                    Text("This meal is no longer available.")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
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
