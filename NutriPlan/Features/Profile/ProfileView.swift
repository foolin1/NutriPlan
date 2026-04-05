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
    @State private var showSavedMessage = false

    var body: some View {
        let draftProfile = buildProfile()
        let previewGoal = GoalCalculator.calculate(for: draftProfile)

        NavigationStack {
            Form {
                Section("Profile") {
                    Picker("Sex", selection: $sex) {
                        ForEach(BiologicalSex.allCases) { value in
                            Text(value.rawValue).tag(value)
                        }
                    }

                    Stepper("Age: \(age)", value: $age, in: 14...100)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Height: \(Int(heightCm)) cm")
                        Slider(value: $heightCm, in: 140...220, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight: \(Int(weightKg)) kg")
                        Slider(value: $weightKg, in: 40...180, step: 1)
                    }

                    Picker("Activity level", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases) { value in
                            Text(value.rawValue).tag(value)
                        }
                    }

                    Picker("Goal", selection: $goalType) {
                        ForEach(GoalType.allCases) { value in
                            Text(value.rawValue).tag(value)
                        }
                    }
                }

                Section("Micronutrient focus") {
                    Picker("Focus", selection: $nutrientFocus) {
                        ForEach(NutrientFocus.allCases) { value in
                            Text(value.displayName).tag(value)
                        }
                    }

                    Text(nutrientFocus.descriptionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Restrictions") {
                    TextField("Allergens (comma separated)", text: $allergensText)
                    TextField("Excluded products (comma separated)", text: $excludedProductsText)
                }

                Section("Target preview") {
                    GoalRow(title: "Calories", value: "\(previewGoal.targetCalories) kcal")
                    GoalRow(title: "Protein", value: "\(previewGoal.proteinGrams) g")
                    GoalRow(title: "Fat", value: "\(previewGoal.fatGrams) g")
                    GoalRow(title: "Carbs", value: "\(previewGoal.carbsGrams) g")
                }

                if let currentProfile = appState.userProfile {
                    Section("Saved profile summary") {
                        GoalRow(title: "Current goal", value: currentProfile.goalType.rawValue)
                        GoalRow(title: "Current activity", value: currentProfile.activityLevel.rawValue)
                        GoalRow(title: "Micronutrient focus", value: currentProfile.nutrientFocus.displayName)
                    }
                }

                Section {
                    Button("Save profile") {
                        appState.updateProfile(draftProfile)
                        showSavedMessage = true
                    }
                    .disabled(!hasUnsavedChanges)

                    Button("Reset onboarding", role: .destructive) {
                        appState.resetProfile()
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("After saving, the daily target is recalculated automatically.")

                        Text("If the updated profile changes calories, goal, activity or restrictions, the daily plan is rebuilt automatically. Diary entries are preserved as factual history.")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if showSavedMessage {
                    Section {
                        Text("Profile saved. Target and current daily plan were updated.")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Profile")
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

    private var hasUnsavedChanges: Bool {
        makeProfileFingerprint(buildProfile()) != makeSavedProfileFingerprint()
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
            excludedProducts: parseList(from: excludedProductsText)
        )
    }

    private func parseList(from text: String) -> [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
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

        return [
            profile.sex.rawValue,
            String(profile.age),
            String(Int(profile.heightCm.rounded())),
            String(Int(profile.weightKg.rounded())),
            profile.activityLevel.rawValue,
            profile.goalType.rawValue,
            profile.nutrientFocus.displayName,
            allergens,
            excludedProducts
        ].joined(separator: "#")
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
