import SwiftUI

private enum AuthMode: String, CaseIterable, Identifiable {
    case signIn = "Вход"
    case signUp = "Регистрация"

    var id: String { rawValue }
}

struct AuthGateView: View {
    @EnvironmentObject private var appState: AppState

    @State private var mode: AuthMode = .signIn
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    modeCard
                    credentialsCard
                    actionsCard
                    statusCard
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Авторизация")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                appState.clearAuthMessages()
            }
        }
    }

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Вход в NutriPlan")
                    .font(.title2.weight(.bold))

                Text("Авторизация нужна, чтобы профиль, дневник и история дней были привязаны к постоянному uid пользователя, а не к текущей версии его профиля.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var modeCard: some View {
        AppCard {
            Picker("Режим", selection: $mode) {
                ForEach(AuthMode.allCases) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var credentialsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Данные аккаунта")
                    .font(.headline)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("Пароль", text: $password)
                    .textFieldStyle(.roundedBorder)

                if mode == .signUp {
                    SecureField("Повтори пароль", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }

                Text(helperText)
                    .font(.caption)
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
                    submit()
                } label: {
                    HStack {
                        Spacer()
                        if appState.isAuthenticating {
                            ProgressView()
                        } else {
                            Text(mode == .signIn ? "Войти" : "Создать аккаунт")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(buttonEnabled ? Color.accentColor.opacity(0.14) : Color.gray.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!buttonEnabled || appState.isAuthenticating)

                Button("Сбросить пароль") {
                    appState.sendPasswordReset(email: normalizedEmail)
                }
                .disabled(normalizedEmail.isEmpty || appState.isAuthenticating)
            }
        }
    }

    @ViewBuilder
    private var statusCard: some View {
        if let error = appState.authErrorMessage {
            AppCard {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
        } else if let info = appState.authInfoMessage {
            AppCard {
                Text(info)
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
        }
    }

    private var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var buttonEnabled: Bool {
        guard !normalizedEmail.isEmpty, password.count >= 8 else {
            return false
        }

        if mode == .signUp {
            return confirmPassword == password
        }

        return true
    }

    private var helperText: String {
        if mode == .signUp {
            return "Для регистрации используй email и пароль не короче 8 символов."
        }

        return "После входа приложение загрузит данные пользователя, связанные с этим аккаунтом."
    }

    private func submit() {
        appState.clearAuthMessages()

        switch mode {
        case .signIn:
            appState.signIn(email: normalizedEmail, password: password)

        case .signUp:
            guard password == confirmPassword else {
                appState.authErrorMessage = "Пароли не совпадают."
                return
            }

            appState.signUp(email: normalizedEmail, password: password)
        }
    }
}
