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
        .navigationTitle("Синхронизация данных")
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

                Text("Здесь можно обновить данные аккаунта на этом устройстве и восстановить сохранённую информацию.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var syncStatusCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Состояние данных")
                    .font(.headline)

                InfoValueRow(
                    title: "Профиль",
                    value: appState.isCloudProfileLiveSyncActive ? "Обновляется автоматически" : "Ожидает обновления"
                )

                InfoValueRow(
                    title: "Последнее обновление профиля",
                    value: formattedDate(appState.lastCloudProfileRestoreAt)
                )

                InfoValueRow(
                    title: "Данные дня",
                    value: vm.isCloudRestoreInProgress ? "Сейчас обновляются" : "Можно обновить вручную"
                )

                InfoValueRow(
                    title: "Последнее обновление данных дня",
                    value: formattedDate(vm.lastCloudRestoreAt)
                )

                Text("Если ты входишь на новом устройстве или после переустановки приложения, здесь можно быстро подтянуть сохранённые данные.")
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

                if let info = appState.authInfoMessage {
                    Text(info)
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if let error = appState.authErrorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
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

                if let message = vm.cloudRestoreMessage {
                    let isError = message.localizedCaseInsensitiveContains("не удалось")

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(isError ? .red : .green)
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
                Text("Что обновляется")
                    .font(.headline)

                restoreBullet("текущий профиль пользователя;")
                restoreBullet("история изменений профиля;")
                restoreBullet("активный день;")
                restoreBullet("архив прошлых дней и записей о питании.")

                Text("Обычно профиль обновляется сам. Ручное обновление пригодится, если ты сменил устройство или хочешь подтянуть последние сохранённые данные.")
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
