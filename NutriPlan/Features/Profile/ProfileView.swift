import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    @State private var sex: BiologicalSex = .male
    @State private var age: Int = 25
    @State private var heightCm: Double = 175
    @State private var weightKg: Double = 75
    @State private var activityLevel: ActivityLevel = .moderate
    @State private var goalType: GoalType = .maintainWeight
    @State private var nutrientFocus: NutrientFocus = .none
    @State private var allergensText: String = ""
    @State private var excludedProductsText: String = ""
    @State private var excludedGroups: Set<String> = []
    @State private var showSavedMessage = false

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                profileSection
                nutrientFocusSection
                excludedGroupsSection
                restrictionsSection
                previewSection
                snapshotsSection
                savedProfileSection
                actionsSection
                savedMessageSection
            }
            .navigationTitle("Профиль")
            .onAppear {
                loadProfile()
            }
            .onChange(of: appState.userProfile) { _ in
                loadProfile()
            }
            .onChange(of: hasUnsavedChanges) { hasChanges in
                if hasChanges {
                    showSavedMessage = false
                }
            }
        }
    }

    private var draftProfile: UserProfile {
        buildProfile()
    }

    private var previewGoal: NutritionGoal {
        GoalCalculator.calculate(for: draftProfile)
    }

    private var hasUnsavedChanges: Bool {
        makeProfileFingerprint(draftProfile) != makeSavedProfileFingerprint()
    }

    private var accountSection: some View {
        Section("Аккаунт") {
            GoalRow(title: "Тип", value: appState.accountTitle)
            GoalRow(title: "Идентификатор", value: appState.accountShortId)
            GoalRow(title: "Хранение", value: appState.accountSyncTitle)

            NavigationLink {
                AccountCenterView()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Открыть центр аккаунта")
                    Text("Посмотреть, как в приложении связаны аккаунт, профиль и история.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Текущий профиль можно менять сколько угодно раз. Это тот же самый пользователь, поэтому история дней и снимки профиля не должны исчезать только из-за изменения веса, цели или ограничений.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var profileSection: some View {
        Section("Профиль") {
            Picker("Пол", selection: $sex) {
                ForEach(BiologicalSex.allCases) { value in
                    Text(value.ruTitle).tag(value)
                }
            }

            Stepper("Возраст: \(age)", value: $age, in: 14...100)

            VStack(alignment: .leading, spacing: 8) {
                Text("Рост: \(Int(heightCm)) см")
                Slider(value: $heightCm, in: 140...220, step: 1)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Вес: \(Int(weightKg)) кг")
                Slider(value: $weightKg, in: 40...180, step: 1)
            }

            Picker("Уровень активности", selection: $activityLevel) {
                ForEach(ActivityLevel.allCases) { value in
                    Text(value.ruTitle).tag(value)
                }
            }

            Picker("Цель", selection: $goalType) {
                ForEach(GoalType.allCases) { value in
                    Text(value.ruTitle).tag(value)
                }
            }
        }
    }

    private var nutrientFocusSection: some View {
        Section("Фокус по микронутриентам") {
            Picker("Фокус", selection: $nutrientFocus) {
                ForEach(NutrientFocus.allCases) { value in
                    Text(value.displayName).tag(value)
                }
            }

            Text(nutrientFocus.descriptionText)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Text("Поддерживаемые показатели")
                    .font(.subheadline.weight(.semibold))

                ForEach(NutrientCatalog.focusable) { nutrient in
                    micronutrientSupportRow(nutrient)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var excludedGroupsSection: some View {
        Section("Исключаемые группы продуктов") {
            ForEach(FoodGroupCatalog.all) { option in
                groupToggle(for: option)
            }
        }
    }

    private var restrictionsSection: some View {
        Section("Ограничения") {
            TextField("Аллергены (через запятую)", text: $allergensText)
            TextField("Исключаемые продукты (через запятую)", text: $excludedProductsText)
        }
    }

    private var previewSection: some View {
        Section("Предпросмотр цели") {
            GoalRow(title: "Калории", value: "\(previewGoal.targetCalories) ккал")
            GoalRow(title: "Белки", value: "\(previewGoal.proteinGrams) г")
            GoalRow(title: "Жиры", value: "\(previewGoal.fatGrams) г")
            GoalRow(title: "Углеводы", value: "\(previewGoal.carbsGrams) г")
            GoalRow(title: "Фокус", value: nutrientFocus.displayName)
        }
    }

    private var snapshotsSection: some View {
        Section("История профиля") {
            NavigationLink {
                ProfileSnapshotsView()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Открыть снимки профиля")
                    Text("Просмотреть, как менялись вес, цель, ограничения и выбранный микронутриентный фокус.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GoalRow(title: "Количество снимков", value: "\(appState.profileSnapshots.count)")
        }
    }

    @ViewBuilder
    private var savedProfileSection: some View {
        if let currentProfile = appState.userProfile {
            Section("Сохранённый профиль") {
                GoalRow(title: "Текущая цель", value: currentProfile.goalType.ruTitle)
                GoalRow(title: "Текущая активность", value: currentProfile.activityLevel.ruTitle)
                GoalRow(title: "Фокус по микронутриентам", value: currentProfile.nutrientFocus.displayName)
                GoalRow(
                    title: "Исключённые группы",
                    value: groupsSummary(from: currentProfile.excludedGroups)
                )
            }
        }
    }

    private var actionsSection: some View {
        Section {
            Button("Сохранить профиль") {
                appState.updateProfile(draftProfile)
                showSavedMessage = true
            }
            .disabled(!hasUnsavedChanges)

            Button("Сбросить текущий профиль", role: .destructive) {
                appState.resetProfile()
            }
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("После сохранения дневная цель пересчитывается автоматически.")
                Text("Архив дней, история аккаунта и снимки профиля не должны теряться из-за изменения веса, цели или ограничений.")
                Text("Фокус по микронутриентам влияет на приоритет блюд при формировании плана.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var savedMessageSection: some View {
        if showSavedMessage {
            Section {
                Text("Профиль сохранён.\nОбновились текущие параметры, фокус по микронутриентам и расчётные рекомендации.")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
        }
    }

    @ViewBuilder
    private func micronutrientSupportRow(_ nutrient: Nutrient) -> some View {
        let isSelected = nutrientFocus.nutrientId == nutrient.id

        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(nutrient.name)
                    .font(.subheadline)

                if let target = nutrient.targetPerDay {
                    Text("Ориентир: \(formatAmount(target, unit: nutrient.unit)) в сутки")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Text("Выбран")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.accentColor)
            }
        }
    }

    @ViewBuilder
    private func groupToggle(for option: FoodGroupOption) -> some View {
        Toggle(isOn: bindingForGroup(option.id)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(option.title)
                Text(option.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func bindingForGroup(_ id: String) -> Binding<Bool> {
        Binding(
            get: { excludedGroups.contains(id) },
            set: { isOn in
                if isOn {
                    excludedGroups.insert(id)
                } else {
                    excludedGroups.remove(id)
                }
            }
        )
    }

    private func loadProfile() {
        guard let profile = appState.userProfile else { return }

        sex = profile.sex
        age = profile.age
        heightCm = profile.heightCm
        weightKg = profile.weightKg
        activityLevel = profile.activityLevel
        goalType = profile.goalType
        nutrientFocus = profile.nutrientFocus
        allergensText = profile.excludedAllergens.joined(separator: ", ")
        excludedProductsText = profile.excludedProducts.joined(separator: ", ")
        excludedGroups = Set(profile.excludedGroups)
    }

    private func buildProfile() -> UserProfile {
        UserProfile(
            sex: sex,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel,
            goalType: goalType,
            nutrientFocus: nutrientFocus,
            excludedAllergens: parseList(from: allergensText),
            excludedProducts: parseList(from: excludedProductsText),
            excludedGroups: excludedGroups.sorted()
        )
    }

    private func parseList(from text: String) -> [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }

    private func groupsSummary(from groups: [String]) -> String {
        if groups.isEmpty {
            return "Нет"
        }

        return groups
            .sorted()
            .map { FoodGroupCatalog.title(for: $0) }
            .joined(separator: ", ")
    }

    private func makeSavedProfileFingerprint() -> String {
        guard let profile = appState.userProfile else { return "" }
        return makeProfileFingerprint(profile)
    }

    private func makeProfileFingerprint(_ profile: UserProfile) -> String {
        let allergens = profile.excludedAllergens
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .sorted()
            .joined(separator: "|")

        let excludedProducts = profile.excludedProducts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .sorted()
            .joined(separator: "|")

        let excludedGroups = profile.excludedGroups
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .sorted()
            .joined(separator: "|")

        return [
            profile.sex.rawValue,
            String(profile.age),
            String(Int(profile.heightCm.rounded())),
            String(Int(profile.weightKg.rounded())),
            profile.activityLevel.rawValue,
            profile.goalType.rawValue,
            profile.nutrientFocus.rawValue,
            allergens,
            excludedProducts,
            excludedGroups
        ].joined(separator: "#")
    }

    private func formatAmount(_ value: Double, unit: String) -> String {
        if unit == "мг" {
            return String(format: "%.0f %@", value, unit)
        }

        return String(format: "%.1f %@", value, unit)
    }
}

private struct GoalRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
