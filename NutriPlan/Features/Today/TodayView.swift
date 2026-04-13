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
                            "Сводка дня",
                            subtitle: "Текущая цель, план питания и фактические показатели за сегодняшний день."
                        )

                        AppCard {
                            Text("Дневная цель")
                                .font(.headline)

                            InfoValueRow(title: "Калории", value: "\(goal.targetCalories) ккал")
                            InfoValueRow(title: "Белки", value: "\(goal.proteinGrams) г")
                            InfoValueRow(title: "Жиры", value: "\(goal.fatGrams) г")
                            InfoValueRow(title: "Углеводы", value: "\(goal.carbsGrams) г")
                        }

                        AppCard {
                            HStack {
                                Text("План на день")
                                    .font(.headline)

                                Spacer()

                                if nutrientFocus == .iron {
                                    StatPill(text: "Фокус: железо")
                                }
                            }

                            InfoValueRow(title: "Калории", value: "\(Int(plannedSummary.macros.calories)) ккал")
                            InfoValueRow(title: "Белки", value: String(format: "%.1f г", plannedSummary.macros.protein))
                            InfoValueRow(title: "Жиры", value: String(format: "%.1f г", plannedSummary.macros.fat))
                            InfoValueRow(title: "Углеводы", value: String(format: "%.1f г", plannedSummary.macros.carbs))

                            if nutrientFocus == .iron {
                                Divider()

                                InfoValueRow(
                                    title: "Железо по плану",
                                    value: String(format: "%.2f мг", plannedSummary.nutrients["iron", default: 0])
                                )
                            }
                        }

                        AppCard {
                            HStack {
                                Text("Факт за день")
                                    .font(.headline)

                                Spacer()

                                if vm.diaryDay.entries.isEmpty {
                                    StatPill(text: "Дневник пуст")
                                }
                            }

                            if vm.diaryDay.entries.isEmpty {
                                Text("Можно переносить блюда из плана или добавлять продукты вручную, если фактическое питание отличалось от плана.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                InfoValueRow(title: "Калории", value: "\(Int(actualSummary.macros.calories)) ккал")
                                InfoValueRow(title: "Белки", value: String(format: "%.1f г", actualSummary.macros.protein))
                                InfoValueRow(title: "Жиры", value: String(format: "%.1f г", actualSummary.macros.fat))
                                InfoValueRow(title: "Углеводы", value: String(format: "%.1f г", actualSummary.macros.carbs))

                                if nutrientFocus == .iron {
                                    Divider()

                                    InfoValueRow(
                                        title: "Железо по факту",
                                        value: String(format: "%.2f мг", actualSummary.nutrients["iron", default: 0])
                                    )
                                }
                            }
                        }
                    }

                    SectionTitleView(
                        "Быстрые действия",
                        subtitle: "Переход к основным сценариям текущего дня и просмотру прошлых записей."
                    )

                    LazyVGrid(columns: actionColumns, spacing: 12) {
                        NavigationLink {
                            DiaryView(vm: vm)
                        } label: {
                            QuickActionTile(
                                systemImage: "book.pages",
                                title: "Дневник",
                                subtitle: "Посмотри записи за день и при необходимости добавь продукты вручную."
                            )
                        }
                        .buttonStyle(.plain)

                        if vm.diaryDay.entries.isEmpty {
                            QuickActionTile(
                                systemImage: "chart.bar.xaxis",
                                title: "План vs факт",
                                subtitle: "Сравнение станет доступно, когда в дневнике появятся записи."
                            )
                        } else {
                            NavigationLink {
                                PlanComparisonView(vm: vm)
                            } label: {
                                QuickActionTile(
                                    systemImage: "chart.bar.xaxis",
                                    title: "План vs факт",
                                    subtitle: "Сравни цель, план и фактическое питание."
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        NavigationLink {
                            PlanHistoryView(vm: vm)
                        } label: {
                            QuickActionTile(
                                systemImage: "clock.arrow.circlepath",
                                title: "История",
                                subtitle: "Открой прошлые дни и посмотри, как менялись план и факт."
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            CloudRestoreView(vm: vm)
                        } label: {
                            QuickActionTile(
                                systemImage: "arrow.triangle.2.circlepath",
                                title: "Синхронизация",
                                subtitle: "Обнови данные аккаунта и историю на этом устройстве."
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if let adjustment {
                        SectionTitleView(
                            "Рекомендация на завтра",
                            subtitle: "Приложение корректирует цель следующего дня по итогам сегодняшнего питания."
                        )

                        AppCard {
                            Text(adjustment.statusTitle)
                                .font(.headline)

                            Text(adjustment.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Divider()

                            InfoValueRow(title: "Калории", value: "\(adjustment.nextDayGoal.targetCalories) ккал")
                            InfoValueRow(title: "Белки", value: "\(adjustment.nextDayGoal.proteinGrams) г")
                            InfoValueRow(title: "Жиры", value: "\(adjustment.nextDayGoal.fatGrams) г")
                            InfoValueRow(title: "Углеводы", value: "\(adjustment.nextDayGoal.carbsGrams) г")

                            if !adjustment.hints.isEmpty {
                                Divider()

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Подсказки")
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
                        "Блюда на сегодня",
                        subtitle: "Список блюд, подобранных системой на текущий день."
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
            .navigationTitle("Сегодня")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var headerSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("NutriPlan")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Главный экран питания на сегодня")
                    .font(.title2.weight(.bold))

                Text("Следи за текущим днём, сравнивай план и факт и получай рекомендации на следующий день без перехода между множеством экранов.")
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
                    Text(meal.type.ruTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(vm.displayTitle(for: meal.recipe))
                        .font(.headline)
                        .multilineTextAlignment(.leading)

                    Text("Калории: \(Int(summary.macros.calories))")
                        .font(.subheadline)

                    Text(
                        "Б: \(summary.macros.protein, specifier: "%.1f") Ж: \(summary.macros.fat, specifier: "%.1f") У: \(summary.macros.carbs, specifier: "%.1f")"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if nutrientFocus == .iron, let iron = summary.nutrients["iron"] {
                        Text("Железо: \(iron, specifier: "%.2f") мг")
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
                        StatPill(text: "Добавлено")
                    }
                }
            }
        }
    }
}
