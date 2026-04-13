import SwiftUI

struct AccountCenterView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                currentAccountCard
                syncCard
                authActionCard
                dataOwnershipCard
                profileMeaningCard
                nextStepCard
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Аккаунт")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            appState.clearAuthMessages()
        }
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Аккаунт")
                    .font(.title2.weight(.bold))

                Text("Аккаунт нужен для того, чтобы твой профиль, история питания и изменения параметров оставались привязаны к одному и тому же пользователю.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var currentAccountCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appState.accountTitle)
                            .font(.headline)

                        Text(appState.accountAuthSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    AccountModeBadge(text: "Подключён")
                }

                Divider()

                InfoValueRow(title: "Идентификатор", value: appState.accountShortId)
                InfoValueRow(title: "Состояние данных", value: appState.accountSyncTitle)

                if let account = appState.account {
                    Divider()
                    InfoValueRow(title: "Пользователь", value: account.displayNameOrFallback)

                    if let email = account.email, !email.isEmpty {
                        InfoValueRow(title: "Email", value: email)
                    }

                    if let linkedAt = account.linkedAt {
                        InfoValueRow(
                            title: "Аккаунт активен с",
                            value: Self.linkedDateFormatter.string(from: linkedAt)
                        )
                    }
                }
            }
        }
    }

    private var syncCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Синхронизация")
                    .font(.headline)

                Text("Профиль и история пользователя сохраняются вместе с аккаунтом. Это помогает восстановить данные после входа на новом устройстве.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                InfoValueRow(
                    title: "Профиль",
                    value: appState.isCloudProfileLiveSyncActive ? "Обновляется автоматически" : "Ожидает обновления"
                )

                InfoValueRow(
                    title: "Последнее обновление",
                    value: formattedDate(appState.lastCloudProfileRestoreAt)
                )

                Text("Обновить данные вручную можно через экран «Синхронизация» на главной странице.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var authActionCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Сеанс")
                    .font(.headline)

                Text("При выходе из аккаунта приложение перестанет показывать связанные с ним данные, пока ты снова не выполнишь вход.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(role: .destructive) {
                    appState.signOut()
                } label: {
                    HStack {
                        Spacer()
                        Text("Выйти из аккаунта")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.red.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)

                if let error = appState.authErrorMessage {
                    Divider()

                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var dataOwnershipCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Что сохраняется вместе с аккаунтом")
                    .font(.headline)

                accountBullet("история дней и прошлых записей;")
                accountBullet("текущий день и дневник питания;")
                accountBullet("список покупок и отметки купленного;")
                accountBullet("текущий профиль и его изменения.")

                Text("Изменение веса, цели или ограничений не создаёт нового пользователя. Это просто обновление твоего текущего профиля.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var profileMeaningCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Профиль и аккаунт")
                    .font(.headline)

                Text("Профиль можно менять по мере прогресса: например, если изменился вес, цель или ограничения. Аккаунт при этом остаётся тем же, поэтому история не теряется.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                InfoValueRow(title: "Изменение профиля", value: "Обновляет будущие планы")
                InfoValueRow(title: "Аккаунт", value: "Сохраняет всю историю")
            }
        }
    }

    private var nextStepCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Что уже работает")
                    .font(.headline)

                accountBullet("вход по email и паролю;")
                accountBullet("сохранение профиля;")
                accountBullet("история изменений профиля;")
                accountBullet("сохранение текущего дня и истории питания.")

                Text("Этого уже достаточно, чтобы продолжать пользоваться приложением на одном или нескольких устройствах под тем же аккаунтом.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func accountBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .font(.subheadline)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "Ещё не выполнялось" }
        return Self.linkedDateFormatter.string(from: date)
    }

    private static let linkedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct AccountModeBadge: View {
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
