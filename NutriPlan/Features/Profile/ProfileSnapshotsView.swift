import SwiftUI

struct ProfileSnapshotsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                if appState.profileSnapshots.isEmpty {
                    emptyState
                } else {
                    SectionTitleView(
                        "История изменений профиля",
                        subtitle: "Каждое сохранение профиля фиксируется как отдельный snapshot и остаётся привязанным к тому же пользователю."
                    )

                    VStack(spacing: 12) {
                        ForEach(appState.profileSnapshots) { snapshot in
                            snapshotCard(snapshot)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("История профиля")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Снимки профиля")
                    .font(.title2.weight(.bold))

                Text("Этот экран показывает, как менялись параметры пользователя со временем: вес, цель, активность, микронутриентный фокус и ограничения.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyState: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("История пока пуста")
                    .font(.headline)

                Text("После первого сохранения профиля и последующих изменений здесь появятся снимки параметров пользователя.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func snapshotCard(_ snapshot: ProfileSnapshot) -> some View {
        let goal = GoalCalculator.calculate(for: snapshot.profile)

        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(formattedDate(snapshot.recordedAt))
                            .font(.headline)

                        Text(formattedTime(snapshot.recordedAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    SnapshotBadge(text: snapshot.shortGoalText)
                }

                Divider()

                VStack(spacing: 8) {
                    InfoValueRow(title: "Вес", value: snapshot.shortWeightText)
                    InfoValueRow(title: "Рост", value: snapshot.shortHeightText)
                    InfoValueRow(title: "Возраст", value: "\(snapshot.profile.age)")
                    InfoValueRow(title: "Активность", value: snapshot.shortActivityText)
                    InfoValueRow(title: "Микронутриентный фокус", value: snapshot.shortNutrientFocusText)
                }

                Divider()

                VStack(spacing: 8) {
                    InfoValueRow(title: "Цель по калориям", value: "\(goal.targetCalories) ккал")
                    InfoValueRow(title: "Белки", value: "\(goal.proteinGrams) г")
                    InfoValueRow(title: "Жиры", value: "\(goal.fatGrams) г")
                    InfoValueRow(title: "Углеводы", value: "\(goal.carbsGrams) г")
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ограничения")
                        .font(.subheadline.weight(.semibold))

                    InfoValueRow(title: "Исключённые группы", value: snapshot.excludedGroupsSummary)
                    InfoValueRow(
                        title: "Аллергены",
                        value: listOrDash(snapshot.profile.excludedAllergens)
                    )
                    InfoValueRow(
                        title: "Исключённые продукты",
                        value: listOrDash(snapshot.profile.excludedProducts)
                    )
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }

    private func listOrDash(_ values: [String]) -> String {
        if values.isEmpty {
            return "Нет"
        }

        return values.joined(separator: ", ")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct SnapshotBadge: View {
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
