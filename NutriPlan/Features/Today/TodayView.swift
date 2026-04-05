import SwiftUI

struct TodayView: View {
    @ObservedObject var vm: PlanViewModel
    @EnvironmentObject private var appState: AppState

    private let actionColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        let plannedSummary = vm.daySummary()
        let actualSummary = vm.actualSummary()
        let adjustment = vm.adjustmentRecommendation()
        let nutrientFocus = appState.userProfile?.nutrientFocus ?? .none

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    if let goal = appState.nutritionGoal {
                        SectionTitleView(
                            "Today overview",
                            subtitle: "Your target, planned nutrition and actual intake for the current day."
                        )

                        AppCard {
                            Text("Daily target")
                                .font(.headline)

                            InfoValueRow(title: "Calories", value: "\(goal.targetCalories) kcal")
                            InfoValueRow(title: "Protein", value: "\(goal.proteinGrams) g")
                            InfoValueRow(title: "Fat", value: "\(goal.fatGrams) g")
                            InfoValueRow(title: "Carbs", value: "\(goal.carbsGrams) g")
                        }

                        AppCard {
                            HStack {
                                Text("Planned total")
                                    .font(.headline)

                                Spacer()

                                if nutrientFocus == .iron {
                                    StatPill(text: "Iron focus")
                                }
                            }

                            InfoValueRow(title: "Calories", value: "\(Int(plannedSummary.macros.calories)) kcal")
                            InfoValueRow(title: "Protein", value: String(format: "%.1f g", plannedSummary.macros.protein))
                            InfoValueRow(title: "Fat", value: String(format: "%.1f g", plannedSummary.macros.fat))
                            InfoValueRow(title: "Carbs", value: String(format: "%.1f g", plannedSummary.macros.carbs))

                            if nutrientFocus == .iron {
                                Divider()
                                InfoValueRow(
                                    title: "Planned iron",
                                    value: String(format: "%.2f mg", plannedSummary.nutrients["iron", default: 0])
                                )
                            }
                        }

                        AppCard {
                            HStack {
                                Text("Actual total")
                                    .font(.headline)

                                Spacer()

                                if vm.diaryDay.entries.isEmpty {
                                    StatPill(text: "No diary yet")
                                }
                            }

                            if vm.diaryDay.entries.isEmpty {
                                Text("Add meals from your plan to the diary to compare planned and actual nutrition.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                InfoValueRow(title: "Calories", value: "\(Int(actualSummary.macros.calories)) kcal")
                                InfoValueRow(title: "Protein", value: String(format: "%.1f g", actualSummary.macros.protein))
                                InfoValueRow(title: "Fat", value: String(format: "%.1f g", actualSummary.macros.fat))
                                InfoValueRow(title: "Carbs", value: String(format: "%.1f g", actualSummary.macros.carbs))

                                if nutrientFocus == .iron {
                                    Divider()
                                    InfoValueRow(
                                        title: "Actual iron",
                                        value: String(format: "%.2f mg", actualSummary.nutrients["iron", default: 0])
                                    )
                                }
                            }
                        }
                    }

                    SectionTitleView(
                        "Quick actions",
                        subtitle: "Fast access to the main daily scenarios."
                    )

                    LazyVGrid(columns: actionColumns, spacing: 12) {
                        NavigationLink {
                            DiaryView(vm: vm)
                        } label: {
                            QuickActionTile(
                                systemImage: "book.pages",
                                title: "Diary",
                                subtitle: "See what you actually ate today."
                            )
                        }
                        .buttonStyle(.plain)

                        if vm.diaryDay.entries.isEmpty {
                            QuickActionTile(
                                systemImage: "chart.bar.xaxis",
                                title: "Plan vs actual",
                                subtitle: "Available after adding entries to the diary."
                            )
                        } else {
                            NavigationLink {
                                PlanComparisonView(vm: vm)
                            } label: {
                                QuickActionTile(
                                    systemImage: "chart.bar.xaxis",
                                    title: "Plan vs actual",
                                    subtitle: "Compare your target, plan and actual nutrition."
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let adjustment {
                        SectionTitleView(
                            "Tomorrow recommendation",
                            subtitle: "The app adjusts the next day target based on today."
                        )

                        AppCard {
                            Text(adjustment.statusTitle)
                                .font(.headline)

                            Text(adjustment.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Divider()

                            InfoValueRow(title: "Calories", value: "\(adjustment.nextDayGoal.targetCalories) kcal")
                            InfoValueRow(title: "Protein", value: "\(adjustment.nextDayGoal.proteinGrams) g")
                            InfoValueRow(title: "Fat", value: "\(adjustment.nextDayGoal.fatGrams) g")
                            InfoValueRow(title: "Carbs", value: "\(adjustment.nextDayGoal.carbsGrams) g")

                            if !adjustment.hints.isEmpty {
                                Divider()

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Hints")
                                        .font(.subheadline.weight(.semibold))

                                    ForEach(adjustment.hints, id: \.self) { hint in
                                        Text("• \(hint)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    SectionTitleView(
                        "Today's meals",
                        subtitle: "Preview the meals generated for the current day."
                    )

                    VStack(spacing: 12) {
                        ForEach(vm.dayPlan.meals) { meal in
                            NavigationLink {
                                RecipeDetailView(mealId: meal.id, vm: vm)
                            } label: {
                                mealCard(for: meal, nutrientFocus: nutrientFocus)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var headerSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("NutriPlan")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Your daily nutrition dashboard")
                    .font(.title2.weight(.bold))

                Text("Track the current day, compare plan and fact, and adjust the next recommendation without leaving the main screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func mealCard(for meal: PlannedMeal, nutrientFocus: NutrientFocus) -> some View {
        let summary = vm.summary(for: meal.recipe)

        AppCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(meal.type.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(vm.displayTitle(for: meal.recipe))
                        .font(.headline)
                        .multilineTextAlignment(.leading)

                    Text("Calories: \(Int(summary.macros.calories))")
                        .font(.subheadline)

                    Text(
                        "P: \(summary.macros.protein, specifier: "%.1f")  F: \(summary.macros.fat, specifier: "%.1f")  C: \(summary.macros.carbs, specifier: "%.1f")"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if nutrientFocus == .iron,
                       let iron = summary.nutrients["iron"] {
                        Text("Iron: \(iron, specifier: "%.2f") mg")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)

                    if vm.isMealLogged(meal.id) {
                        StatPill(text: "Added")
                    }
                }
            }
        }
    }
}
