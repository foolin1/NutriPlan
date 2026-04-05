import SwiftUI

struct DiaryView: View {

    @ObservedObject var vm: PlanViewModel

    var body: some View {
        let actualSummary = vm.actualSummary()

        List {
            if vm.diaryDay.entries.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Diary is empty")
                            .font(.headline)
                        Text("Add meals from your daily plan to see what you actually ate.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            } else {
                Section("Actual total") {
                    GoalInfoRow(title: "Calories", value: "\(Int(actualSummary.macros.calories)) kcal")
                    GoalInfoRow(title: "Protein", value: String(format: "%.1f g", actualSummary.macros.protein))
                    GoalInfoRow(title: "Fat", value: String(format: "%.1f g", actualSummary.macros.fat))
                    GoalInfoRow(title: "Carbs", value: String(format: "%.1f g", actualSummary.macros.carbs))

                    if let iron = actualSummary.nutrients["iron"] {
                        GoalInfoRow(title: "Iron", value: String(format: "%.2f mg", iron))
                    }
                }

                ForEach(MealType.allCases) { mealType in
                    let entries = vm.diaryDay.entries.filter { $0.mealType == mealType }

                    if !entries.isEmpty {
                        Section(mealType.rawValue) {
                            ForEach(entries) { entry in
                                let s = vm.summary(for: entry.recipe)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(entry.title)
                                        .font(.headline)

                                    Text("Calories: \(Int(s.macros.calories))")
                                        .font(.subheadline)

                                    Text("P: \(s.macros.protein, specifier: "%.1f")  F: \(s.macros.fat, specifier: "%.1f")  C: \(s.macros.carbs, specifier: "%.1f")")
                                        .font(.caption)

                                    if let iron = s.nutrients["iron"] {
                                        Text("Iron: \(iron, specifier: "%.2f") mg")
                                            .font(.caption2)
                                    }
                                }
                                .padding(.vertical, 6)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        vm.removeDiaryEntry(id: entry.id)
                                    } label: {
                                        Text("Delete")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Diary")
        .toolbar {
            if !vm.diaryDay.entries.isEmpty {
                Button("Clear") {
                    vm.clearDiary()
                }
            }
        }
    }
}

private struct GoalInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
