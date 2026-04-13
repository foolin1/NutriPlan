import SwiftUI

struct DiaryView: View {
    @ObservedObject var vm: PlanViewModel
    @State private var showManualEntrySheet = false

    var body: some View {
        let actualSummary = vm.actualSummary()

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                if vm.diaryDay.entries.isEmpty {
                    emptyState
                } else {
                    actionsCard

                    SectionTitleView(
                        "Итог по факту",
                        subtitle: "Сводка строится на основе блюд и продуктов, которые реально были добавлены в дневник."
                    )

                    AppCard {
                        VStack(spacing: 10) {
                            InfoValueRow(title: "Калории", value: "\(Int(actualSummary.macros.calories)) ккал")
                            InfoValueRow(title: "Белки", value: String(format: "%.1f г", actualSummary.macros.protein))
                            InfoValueRow(title: "Жиры", value: String(format: "%.1f г", actualSummary.macros.fat))
                            InfoValueRow(title: "Углеводы", value: String(format: "%.1f г", actualSummary.macros.carbs))

                            if let iron = actualSummary.nutrients["iron"] {
                                Divider()
                                InfoValueRow(title: "Железо", value: String(format: "%.2f мг", iron))
                            }
                        }
                    }

                    ForEach(MealType.allCases) { mealType in
                        let entries = vm.diaryDay.entries.filter { $0.mealType == mealType }

                        if !entries.isEmpty {
                            SectionTitleView(
                                mealType.ruTitle,
                                subtitle: "Фактические записи по этому приёму пищи."
                            )

                            VStack(spacing: 12) {
                                ForEach(entries) { entry in
                                    let summary = vm.summary(for: entry.recipe)

                                    DiaryLoggedEntryCard(
                                        title: entry.title,
                                        mealType: entry.mealType.ruTitle,
                                        sourceText: entry.mealId == nil ? "Добавлено вручную" : "Перенесено из плана",
                                        caloriesText: "\(Int(summary.macros.calories)) ккал",
                                        proteinText: String(format: "%.1f г", summary.macros.protein),
                                        fatText: String(format: "%.1f г", summary.macros.fat),
                                        carbsText: String(format: "%.1f г", summary.macros.carbs),
                                        ironText: summary.nutrients["iron"].map { String(format: "%.2f мг", $0) }
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
        .navigationTitle("Дневник")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Добавить вручную") {
                    showManualEntrySheet = true
                }

                if !vm.diaryDay.entries.isEmpty {
                    Button("Очистить") {
                        vm.clearDiary()
                    }
                }
            }
        }
        .sheet(isPresented: $showManualEntrySheet) {
            ManualDiaryEntryView(vm: vm)
        }
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Дневник питания")
                    .font(.title2.weight(.bold))

                Text("Здесь хранится фактическое питание за текущий день. Можно переносить блюда из плана или добавлять отдельные продукты вручную.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionsCard: some View {
        VStack(spacing: 12) {
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Быстрые действия")
                        .font(.headline)

                    Button {
                        showManualEntrySheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Добавить продукт вручную")
                                    .font(.headline)

                                Text("Выбери продукт из каталога, укажи граммовку и приём пищи.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

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

                    NavigationLink {
                        PlanComparisonView(vm: vm)
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Открыть сравнение")
                                    .font(.headline)

                                Text("Сопоставь цель, план и фактическое питание за день.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Дневник пока пуст")
                    .font(.headline)

                Text("Добавь продукт вручную, если фактическое питание отличалось от плана, или перенеси блюда из экрана плана.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    showManualEntrySheet = true
                } label: {
                    Text("Добавить запись вручную")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.accentColor.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct DiaryLoggedEntryCard: View {
    let title: String
    let mealType: String
    let sourceText: String
    let caloriesText: String
    let proteinText: String
    let fatText: String
    let carbsText: String
    let ironText: String?
    let onDelete: () -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(mealType)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(title)
                            .font(.headline)

                        Text(sourceText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                }

                Divider()

                VStack(spacing: 8) {
                    InfoValueRow(title: "Калории", value: caloriesText)
                    InfoValueRow(title: "Белки", value: proteinText)
                    InfoValueRow(title: "Жиры", value: fatText)
                    InfoValueRow(title: "Углеводы", value: carbsText)

                    if let ironText {
                        Divider()
                        InfoValueRow(title: "Железо", value: ironText)
                    }
                }
            }
        }
    }
}
