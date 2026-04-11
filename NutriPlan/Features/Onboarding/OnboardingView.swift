import SwiftUI

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let previewGoal = GoalCalculator.calculate(for: vm.buildProfile())

        NavigationStack {
            Form {
                Section("Основная информация") {
                    Picker("Пол", selection: $vm.sex) {
                        ForEach(BiologicalSex.allCases) { sex in
                            Text(sex.ruTitle).tag(sex)
                        }
                    }

                    Stepper("Возраст: \(vm.age)", value: $vm.age, in: 14...100)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Рост: \(Int(vm.heightCm)) см")
                        Slider(value: $vm.heightCm, in: 140...220, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Вес: \(Int(vm.weightKg)) кг")
                        Slider(value: $vm.weightKg, in: 40...180, step: 1)
                    }

                    Picker("Уровень активности", selection: $vm.activityLevel) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.ruTitle).tag(level)
                        }
                    }

                    Picker("Цель", selection: $vm.goalType) {
                        ForEach(GoalType.allCases) { goal in
                            Text(goal.ruTitle).tag(goal)
                        }
                    }
                }

                Section("Фокус по микронутриентам") {
                    Picker("Фокус", selection: $vm.nutrientFocus) {
                        ForEach(NutrientFocus.allCases) { focus in
                            Text(focus.displayName).tag(focus)
                        }
                    }

                    Text(vm.nutrientFocus.descriptionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Ограничения") {
                    TextField("Аллергены (через запятую)", text: $vm.allergensText)
                    TextField("Исключаемые продукты (через запятую)", text: $vm.excludedProductsText)
                }

                Section("Предпросмотр дневной цели") {
                    GoalRow(title: "Калории", value: "\(previewGoal.targetCalories) ккал")
                    GoalRow(title: "Белки", value: "\(previewGoal.proteinGrams) г")
                    GoalRow(title: "Жиры", value: "\(previewGoal.fatGrams) г")
                    GoalRow(title: "Углеводы", value: "\(previewGoal.carbsGrams) г")
                }

                Section {
                    Button {
                        appState.completeOnboarding(with: vm.buildProfile())
                    } label: {
                        Text("Продолжить")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(!vm.canContinue)
                }
            }
            .navigationTitle("Начальная настройка")
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
