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
                        "Фактический итог",
                        subtitle: "Пищевые показатели на основе блюд и продуктов, добавленных в дневник."
                    )

                    AppCard {
                        RecipeSummaryGrid(
                            caloriesText: "\(Int(actualSummary.macros.calories)) ккал",
                            proteinText: String(format: "%.1f г", actualSummary.macros.protein),
                            fatText: String(format: "%.1f г", actualSummary.macros.fat),
                            carbsText: String(format: "%.1f г", actualSummary.macros.carbs),
                            ironText: actualSummary.nutrients["iron"].map { String(format: "%.2f мг", $0) }
                        )
                    }

                    ForEach(MealType.allCases) { mealType in
                        let entries = vm.diaryDay.entries.filter { $0.mealType == mealType }

                        if !entries.isEmpty {
                            SectionTitleView(
                                mealType.ruTitle,
                                subtitle: "Записи дневника для этого приёма пищи."
                            )

                            VStack(spacing: 12) {
                                ForEach(entries) { entry in
                                    let summary = vm.summary(for: entry.recipe)

                                    DiaryEntryCard(
                                        title: entry.title,
                                        mealType: entry.mealType.ruTitle,
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

                Text("Здесь можно хранить то, что было съедено фактически: либо переносить блюда из плана, либо добавлять продукты вручную.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Действия")
                    .font(.headline)

                Button {
                    showManualEntrySheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Добавить вручную")
                                .font(.headline)

                            Text("Выбери продукт из каталога и укажи его количество.")
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
            }
        }
    }

    private var emptyState: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Дневник пуст")
                    .font(.headline)

                Text("Можно переносить блюда из плана или добавить продукт вручную, если ты ел не по предложенному меню.")
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
