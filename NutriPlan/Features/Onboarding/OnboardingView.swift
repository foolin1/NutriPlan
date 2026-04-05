import SwiftUI

struct OnboardingView: View {

    @StateObject private var vm = OnboardingViewModel()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let previewGoal = GoalCalculator.calculate(for: vm.buildProfile())

        NavigationStack {
            Form {
                Section("About you") {
                    Picker("Sex", selection: $vm.sex) {
                        ForEach(BiologicalSex.allCases) { sex in
                            Text(sex.rawValue).tag(sex)
                        }
                    }

                    Stepper("Age: \(vm.age)", value: $vm.age, in: 14...100)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Height: \(Int(vm.heightCm)) cm")
                        Slider(value: $vm.heightCm, in: 140...220, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight: \(Int(vm.weightKg)) kg")
                        Slider(value: $vm.weightKg, in: 40...180, step: 1)
                    }

                    Picker("Activity level", selection: $vm.activityLevel) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }

                    Picker("Goal", selection: $vm.goalType) {
                        ForEach(GoalType.allCases) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                }

                Section("Micronutrient focus") {
                    Picker("Focus", selection: $vm.nutrientFocus) {
                        ForEach(NutrientFocus.allCases) { focus in
                            Text(focus.displayName).tag(focus)
                        }
                    }

                    Text(vm.nutrientFocus.descriptionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Restrictions") {
                    TextField("Allergens (comma separated)", text: $vm.allergensText)
                    TextField("Excluded products (comma separated)", text: $vm.excludedProductsText)
                }

                Section("Daily target preview") {
                    GoalRow(title: "Calories", value: "\(previewGoal.targetCalories) kcal")
                    GoalRow(title: "Protein", value: "\(previewGoal.proteinGrams) g")
                    GoalRow(title: "Fat", value: "\(previewGoal.fatGrams) g")
                    GoalRow(title: "Carbs", value: "\(previewGoal.carbsGrams) g")
                }

                Section {
                    Button {
                        appState.completeOnboarding(with: vm.buildProfile())
                    } label: {
                        Text("Continue")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(!vm.canContinue)
                }
            }
            .navigationTitle("NutriPlan setup")
        }
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
