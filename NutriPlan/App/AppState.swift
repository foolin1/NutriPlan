import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {

    @Published var userProfile: UserProfile? {
        didSet {
            persistProfile()
            nutritionGoal = userProfile.map { GoalCalculator.calculate(for: $0) }
        }
    }

    @Published private(set) var nutritionGoal: NutritionGoal?

    private let userDefaultsKey = "nutriplan.userProfile"

    init() {
        loadProfile()
    }

    func completeOnboarding(with profile: UserProfile) {
        userProfile = profile
    }

    func resetProfile() {
        userProfile = nil
        nutritionGoal = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    private func loadProfile() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }

        do {
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            userProfile = profile
        } catch {
            print("Failed to load profile: \(error)")
        }
    }

    private func persistProfile() {
        guard let userProfile else { return }

        do {
            let data = try JSONEncoder().encode(userProfile)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
}
