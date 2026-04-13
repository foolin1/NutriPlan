import SwiftUI

struct CloudArchitectureView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                collectionsCard
                securityCard
                behaviorCard
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Cloud-архитектура")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Cloud-архитектура данных")
                    .font(.title2.weight(.bold))

                Text("Ниже показано, как данные пользователя разложены в Firestore. Все документы должны быть привязаны к uid авторизованного пользователя.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var collectionsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Используемые пути")
                    .font(.headline)

                CloudPathRow(
                    title: "Текущий профиль",
                    path: "users/{uid}/profile/current",
                    subtitle: "Актуальные параметры пользователя: вес, рост, цель, активность, ограничения."
                )

                CloudPathRow(
                    title: "Снимки профиля",
                    path: "users/{uid}/profileSnapshots/{snapshotId}",
                    subtitle: "История изменения профиля: как менялись вес, цель и ограничения."
                )

                CloudPathRow(
                    title: "Текущий день",
                    path: "users/{uid}/dayState/current",
                    subtitle: "Активная сессия дня: план, факт, покупки и текущее состояние."
                )

                CloudPathRow(
                    title: "Архив дней",
                    path: "users/{uid}/dayHistory/{dayId}",
                    subtitle: "Завершённые дни с сохранённым планом, фактом и историей."
                )
            }
        }
    }

    private var securityCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Что должны делать правила")
                    .font(.headline)

                securityBullet("разрешать доступ только авторизованному пользователю;")
                securityBullet("сравнивать путь документа с request.auth.uid;")
                securityBullet("запрещать доступ ко всем чужим данным;")
                securityBullet("запрещать любые неописанные пути по умолчанию.")

                Text("Именно поэтому test mode нужен только на старте. После появления авторизации правила нужно перевести на owner-based доступ.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var behaviorCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Как это работает в приложении")
                    .font(.headline)

                InfoValueRow(title: "Авторизация", value: "Firebase Auth / email-password")
                InfoValueRow(title: "Идентичность", value: "uid пользователя")
                InfoValueRow(title: "Профиль", value: "Можно менять без потери истории")
                InfoValueRow(title: "История", value: "Остаётся привязанной к тому же uid")
            }
        }
    }

    @ViewBuilder
    private func securityBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .font(.subheadline)
    }
}

private struct CloudPathRow: View {
    let title: String
    let path: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(path)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
