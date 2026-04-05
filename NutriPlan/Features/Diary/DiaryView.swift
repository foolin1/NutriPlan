import SwiftUI

struct DiaryView: View {
    @ObservedObject var vm: PlanViewModel

    var body: some View {
        let actualSummary = vm.actualSummary()

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                if vm.diaryDay.entries.isEmpty {
                    emptyState
                } else {
                    SectionTitleView(
                        "Actual total",
                        subtitle: "Nutrition values based on the meals already added to the diary."
                    )

                    AppCard {
                        RecipeSummaryGrid(
                            caloriesText: "\(Int(actualSummary.macros.calories)) kcal",
                            proteinText: String(format: "%.1f g", actualSummary.macros.protein),
                            fatText: String(format: "%.1f g", actualSummary.macros.fat),
                            carbsText: String(format: "%.1f g", actualSummary.macros.carbs),
                            ironText: actualSummary.nutrients["iron"].map { String(format: "%.2f mg", $0) }
                        )
                    }

                    ForEach(MealType.allCases) { mealType in
                        let entries = vm.diaryDay.entries.filter { $0.mealType == mealType }

                        if !entries.isEmpty {
                            SectionTitleView(
                                mealType.rawValue,
                                subtitle: "Meals logged in the diary for this part of the day."
                            )

                            VStack(spacing: 12) {
                                ForEach(entries) { entry in
                                    let summary = vm.summary(for: entry.recipe)

                                    DiaryEntryCard(
                                        title: entry.title,
                                        mealType: entry.mealType.rawValue,
                                        caloriesText: "\(Int(summary.macros.calories)) kcal",
                                        proteinText: String(format: "%.1f g", summary.macros.protein),
                                        fatText: String(format: "%.1f g", summary.macros.fat),
                                        carbsText: String(format: "%.1f g", summary.macros.carbs),
                                        ironText: summary.nutrients["iron"].map { String(format: "%.2f mg", $0) }
                                    ) {
                                        vm.removeDiaryEntry(id: entry.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Diary")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !vm.diaryDay.entries.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        vm.clearDiary()
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Food diary")
                    .font(.title2.weight(.bold))

                Text("This screen stores the meals that were actually consumed and is later used for comparison with the daily plan.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyState: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Diary is empty")
                    .font(.headline)

                Text("Add meals from your daily plan to see what you actually ate and compare plan with fact.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
