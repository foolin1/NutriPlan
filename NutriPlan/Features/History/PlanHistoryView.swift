import SwiftUI

struct PlanHistoryView: View {
    @ObservedObject var vm: PlanViewModel

    var body: some View {
        let records = vm.historyRecords()

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                if records.isEmpty {
                    emptyState
                } else {
                    SectionTitleView(
                        "Прошлые дни",
                        subtitle: "Здесь сохраняются завершённые дни: их план, факт и краткий итог по питанию."
                    )

                    VStack(spacing: 12) {
                        ForEach(records) { record in
                            NavigationLink {
                                PlanHistoryDayDetailView(vm: vm, record: record)
                            } label: {
                                historyCard(for: record)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("История")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("История питания")
                    .font(.title2.weight(.bold))

                Text("Просматривай предыдущие дни, чтобы видеть, как менялись план питания, фактические записи и рекомендации.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func historyCard(for record: PlanHistoryRecord) -> some View {
        let planned = plannedSummary(for: record)
        let actual = actualSummary(for: record)
        let shoppingItems = shoppingItems(for: record)
        let checkedCount = shoppingItems.filter { record.checkedShoppingItemIds.contains($0.id) }.count

        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(displayTitle(for: record.dayId))
                            .font(.headline)

                        Text(displaySubtitle(for: record.dayId))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HistoryStatusPill(text: statusText(for: record, planned: planned, actual: actual))
                }

                VStack(spacing: 8) {
                    HistoryMetricRow(title: "План", value: "\(Int(planned.macros.calories)) ккал")
                    HistoryMetricRow(
                        title: "Факт",
                        value: record.diaryDay.entries.isEmpty
                            ? "нет записей"
                            : "\(Int(actual.macros.calories)) ккал"
                    )
                    HistoryMetricRow(
                        title: "Покупки",
                        value: shoppingItems.isEmpty
                            ? "нет данных"
                            : "\(checkedCount) из \(shoppingItems.count)"
                    )
                }

                HStack {
                    Text("Открыть детали дня")
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private func plannedSummary(for record: PlanHistoryRecord) -> NutritionSummary {
        summarize(recipes: record.dayPlan.meals.map(\.recipe))
    }

    private func actualSummary(for record: PlanHistoryRecord) -> NutritionSummary {
        summarize(recipes: record.diaryDay.entries.map(\.recipe))
    }

    private func summarize(recipes: [Recipe]) -> NutritionSummary {
        var totalMacros = Macros.zero
        var totalNutrients: [String: Double] = [:]

        for recipe in recipes {
            let summary = vm.summary(for: recipe)
            totalMacros = totalMacros + summary.macros

            for (key, value) in summary.nutrients {
                totalNutrients[key, default: 0] += value
            }
        }

        return NutritionSummary(macros: totalMacros, nutrients: totalNutrients)
    }

    private func shoppingItems(for record: PlanHistoryRecord) -> [ShoppingItem] {
        ShoppingListBuilder.build(
            recipes: record.dayPlan.meals.map(\.recipe),
            foodsById: vm.foodsById
        )
    }

    private func statusText(
        for record: PlanHistoryRecord,
        planned: NutritionSummary,
        actual: NutritionSummary
    ) -> String {
        guard !record.diaryDay.entries.isEmpty else {
            return "Без факта"
        }

        let delta = actual.macros.calories - planned.macros.calories

        if abs(delta) <= 120 {
            return "Близко к плану"
        }

        if delta > 120 {
            return "Перебор"
        }

        return "Недобор"
    }

    private func displayTitle(for dayId: String) -> String {
        guard let date = Self.storageFormatter.date(from: dayId) else {
            return dayId
        }

        let calendar = Calendar.current

        if calendar.isDateInYesterday(date) {
            return "Вчера"
        }

        return Self.displayFormatter.string(from: date)
    }

    private func displaySubtitle(for dayId: String) -> String {
        guard let date = Self.storageFormatter.date(from: dayId) else {
            return "Архивный день"
        }

        return Self.weekdayFormatter.string(from: date)
    }

    private var emptyState: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("История пока пуста")
                    .font(.headline)

                Text("Записи здесь появятся автоматически, когда завершится текущий день и приложение сохранит его в архив.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private static let storageFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}

private struct HistoryMetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

private struct HistoryStatusPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
    }
}
