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
    @State private var didInitialLoadProfile = false

    var body: some View {
        NavigationStack {
            Form {
                overviewSection
                mainProfileSection
                nutrientFocusSection
                preferencesSection
                accountAndHistorySection
                actionsSection
                savedMessageSection
            }
            .navigationTitle("Профиль")
            .onAppear {
                guard !didInitialLoadProfile else { return }
                loadProfile()
                didInitialLoadProfile = true
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

    private var overviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                Text("Кратко")
                    .font(.headline)

                HStack(spacing: 12) {
                    summaryTile(title: "Цель", value: goalType.ruTitle)
                    summaryTile(title: "Калории", value: "\(previewGoal.targetCalories)")
                }

                HStack(spacing: 12) {
                    summaryTile(title: "Фокус", value: nutrientFocus.shortTitle)
                    summaryTile(title: "Ограничения", value: "\(restrictionsCount)")
                }

                if !excludedGroups.isEmpty || restrictionsCount > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        if !excludedGroups.isEmpty {
                            Text("Исключённые группы: \(groupsSummary(from: excludedGroups.sorted()))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if restrictionsCount > 0 {
                            Text(restrictionsSummaryDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var mainProfileSection: some View {
        Section("Основные параметры") {
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

            VStack(alignment: .leading, spacing: 8) {
                Text("Дневная цель рассчитывается автоматически на основе текущих параметров профиля.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    compactMetric(title: "Белки", value: "\(previewGoal.proteinGrams) г")
                    compactMetric(title: "Жиры", value: "\(previewGoal.fatGrams) г")
                    compactMetric(title: "Углеводы", value: "\(previewGoal.carbsGrams) г")
                }
            }
            .padding(.top, 4)
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
                ForEach(NutrientCatalog.focusable) { nutrient in
                    micronutrientSupportRow(nutrient)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var preferencesSection: some View {
        Section("Пищевые предпочтения") {
            NavigationLink {
                ExcludedGroupsPickerView(selection: $excludedGroups)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Исключаемые группы")
                        Spacer()
                        Text(excludedGroupsSummaryShort)
                            .foregroundStyle(.secondary)
                    }

                    Text(excludedGroupsSummaryDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            NavigationLink {
                RestrictionsEditorView(
                    allergensText: $allergensText,
                    excludedProductsText: $excludedProductsText
                )
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Ограничения")
                        Spacer()
                        Text(restrictionsSummaryShort)
                            .foregroundStyle(.secondary)
                    }

                    Text(restrictionsSummaryDescriptionShort)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private var accountAndHistorySection: some View {
        Section("Аккаунт и данные") {
            GoalRow(title: "Тип аккаунта", value: appState.accountTitle)
            GoalRow(title: "Хранение", value: appState.accountSyncTitle)
            GoalRow(title: "Снимков профиля", value: "\(appState.profileSnapshots.count)")

            NavigationLink {
                AccountCenterView()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Управление аккаунтом")
                    Text("Вход, синхронизация и восстановление данных.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            NavigationLink {
                ProfileSnapshotsView()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("История профиля")
                    Text("Посмотреть, как менялись вес, цель и ограничения.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
            Text("После сохранения профиль, рекомендации и дневная цель обновятся автоматически.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var savedMessageSection: some View {
        if showSavedMessage {
            Section {
                Text("Профиль сохранён.\nОбновлены параметры пользователя и расчётные рекомендации.")
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
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    @ViewBuilder
    private func summaryTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }

    @ViewBuilder
    private func compactMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var excludedGroupsSummaryShort: String {
        excludedGroups.isEmpty ? "Нет" : "\(excludedGroups.count)"
    }

    private var excludedGroupsSummaryDescription: String {
        if excludedGroups.isEmpty {
            return "Сейчас группы продуктов не исключены."
        }
        return groupsSummary(from: excludedGroups.sorted())
    }

    private var restrictionsCount: Int {
        parseList(from: allergensText).count + parseList(from: excludedProductsText).count
    }

    private var restrictionsSummaryShort: String {
        restrictionsCount == 0 ? "Нет" : "\(restrictionsCount)"
    }

    private var restrictionsSummaryDescriptionShort: String {
        if restrictionsCount == 0 {
            return "Аллергены и отдельные продукты пока не указаны."
        }

        let allergens = parseList(from: allergensText)
        let products = parseList(from: excludedProductsText)

        if !allergens.isEmpty && !products.isEmpty {
            return "Есть аллергены и исключённые продукты."
        } else if !allergens.isEmpty {
            return "Указаны аллергены."
        } else {
            return "Указаны исключённые продукты."
        }
    }

    private var restrictionsSummaryDescription: String {
        let allergens = parseList(from: allergensText)
        let products = parseList(from: excludedProductsText)

        if allergens.isEmpty && products.isEmpty {
            return "Аллергены и отдельные продукты пока не указаны."
        }

        var parts: [String] = []

        if !allergens.isEmpty {
            parts.append("Аллергены: \(allergens.joined(separator: ", "))")
        }

        if !products.isEmpty {
            parts.append("Исключённые продукты: \(products.joined(separator: ", "))")
        }

        return parts.joined(separator: " • ")
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
