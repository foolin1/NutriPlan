import SwiftUI

struct CloudRestoreView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var vm: PlanViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                syncStatusCard
                profileRestoreCard
                dayRestoreCard
                helpCard
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Синхронизация")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            appState.clearAuthMessages()
        }
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Синхронизация данных")
                    .font(.title2.weight(.bold))

                Text("На этом экране можно вручную подтянуть профиль и данные дня из аккаунта, если ты вошёл на новом устройстве или хочешь обновить сохранённую информацию.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var syncStatusCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Текущее состояние")
                    .font(.headline)

                InfoValueRow(
                    title: "Профиль",
                    value: appState.isCloudProfileLiveSyncActive
                        ? "Синхронизируется автоматически"
                        : "Можно обновить вручную"
                )

                InfoValueRow(
                    title: "Последнее обновление профиля",
                    value: formattedDate(appState.lastCloudProfileRestoreAt)
                )

                InfoValueRow(
                    title: "Данные дня",
                    value: vm.isCloudRestoreInProgress
                        ? "Сейчас обновляются"
                        : "Можно обновить вручную"
                )

                InfoValueRow(
                    title: "Последнее обновление данных дня",
                    value: formattedDate(vm.lastCloudRestoreAt)
                )

                Text("Если приложение было переустановлено или ты вошёл на другом устройстве, здесь можно быстро восстановить последние сохранённые данные.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var profileRestoreCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Профиль")
                    .font(.headline)

                Text("Обновляет параметры пользователя, ограничения и связанные с профилем изменения.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let info = appState.authInfoMessage {
                    Text(info)
                        .font(.caption)
                        .foregroundStyle(Color.green)
                }

                if let error = appState.authErrorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }

                Button {
                    appState.reloadCloudProfileData()
                } label: {
                    HStack {
                        Spacer()

                        if appState.isCloudProfileRestoreInProgress {
                            ProgressView()
                        } else {
                            Text("Обновить профиль")
                                .font(.headline)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.accentColor.opacity(0.14))
                    )
                }
                .buttonStyle(.plain)
                .disabled(appState.isCloudProfileRestoreInProgress)
            }
        }
    }

    private var dayRestoreCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Текущий день и история")
                    .font(.headline)

                Text("Обновляет активный день, дневник и историю прошлых записей о питании.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let message = vm.cloudRestoreMessage {
                    let isError = message.localizedCaseInsensitiveContains("не удалось")

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(isError ? Color.red : Color.green)
                }

                Button {
                    vm.reloadCloudState()
                } label: {
                    HStack {
                        Spacer()

                        if vm.isCloudRestoreInProgress {
                            ProgressView()
                        } else {
                            Text("Обновить данные дня")
                                .font(.headline)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.accentColor.opacity(0.14))
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.isCloudRestoreInProgress)
            }
        }
    }

    private var helpCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Что восстанавливается")
                    .font(.headline)

                restoreBullet("текущий профиль пользователя;")
                restoreBullet("история изменений профиля;")
                restoreBullet("активный день;")
                restoreBullet("архив прошлых дней и записей о питании.")

                Text("Обычно профиль обновляется автоматически. Ручная синхронизация нужна, если ты сменил устройство или хочешь подтянуть последние сохранённые данные сразу.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func restoreBullet(_ text: String) -> some View {
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
        return Self.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
