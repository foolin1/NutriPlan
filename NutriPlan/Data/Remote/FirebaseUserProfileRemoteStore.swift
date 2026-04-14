import Foundation
import FirebaseFirestore

protocol UserProfileRemoteStore {
    func fetchProfile(uid: String) async throws -> UserProfile?
    func saveProfile(_ profile: UserProfile, uid: String) async throws
    func observeProfile(
        uid: String,
        onChange: @escaping (Result<UserProfile?, Error>) -> Void
    ) -> CloudListenerToken
}

final class FirebaseUserProfileRemoteStore: UserProfileRemoteStore {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func fetchProfile(uid: String) async throws -> UserProfile? {
        let snapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DocumentSnapshot, Error>) in
            profileDocument(uid: uid).getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let snapshot else {
                    continuation.resume(throwing: NSError(
                        domain: "NutriPlan.Firestore",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Не удалось получить документ профиля."]
                    ))
                    return
                }

                continuation.resume(returning: snapshot)
            }
        }

        guard snapshot.exists, let data = snapshot.data() else {
            return nil
        }

        return mapProfile(from: data)
    }

    func saveProfile(_ profile: UserProfile, uid: String) async throws {
        let payload = makePayload(from: profile)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            profileDocument(uid: uid).setData(payload, merge: true) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func observeProfile(
        uid: String,
        onChange: @escaping (Result<UserProfile?, Error>) -> Void
    ) -> CloudListenerToken {
        let registration = profileDocument(uid: uid).addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }

            guard let snapshot else {
                onChange(.success(nil))
                return
            }

            guard snapshot.exists, let data = snapshot.data() else {
                onChange(.success(nil))
                return
            }

            onChange(.success(self.mapProfile(from: data)))
        }

        return FirestoreListenerToken(registration: registration)
    }

    private func profileDocument(uid: String) -> DocumentReference {
        db.collection("users")
            .document(uid)
            .collection("profile")
            .document("current")
    }

    private func makePayload(from profile: UserProfile) -> [String: Any] {
        [
            "sex": profile.sex.rawValue,
            "age": profile.age,
            "heightCm": profile.heightCm,
            "weightKg": profile.weightKg,
            "activityLevel": profile.activityLevel.rawValue,
            "goalType": profile.goalType.rawValue,
            "nutrientFocus": profile.nutrientFocus.rawValue,
            "excludedAllergens": profile.excludedAllergens,
            "excludedProducts": profile.excludedProducts,
            "excludedGroups": profile.excludedGroups,
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }

    private func mapProfile(from data: [String: Any]) -> UserProfile? {
        guard
            let sexRaw = data["sex"] as? String,
            let sex = BiologicalSex(rawValue: sexRaw),
            let age = intValue(from: data["age"]),
            let heightCm = doubleValue(from: data["heightCm"]),
            let weightKg = doubleValue(from: data["weightKg"]),
            let activityLevelRaw = data["activityLevel"] as? String,
            let activityLevel = ActivityLevel(rawValue: activityLevelRaw),
            let goalTypeRaw = data["goalType"] as? String,
            let goalType = GoalType(rawValue: goalTypeRaw)
        else {
            return nil
        }

        let nutrientFocusStored = data["nutrientFocus"] as? String
        let nutrientFocus = NutrientFocus.resolve(from: nutrientFocusStored)

        let excludedAllergens = data["excludedAllergens"] as? [String] ?? []
        let excludedProducts = data["excludedProducts"] as? [String] ?? []
        let excludedGroups = data["excludedGroups"] as? [String] ?? []

        return UserProfile(
            sex: sex,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel,
            goalType: goalType,
            nutrientFocus: nutrientFocus,
            excludedAllergens: excludedAllergens,
            excludedProducts: excludedProducts,
            excludedGroups: excludedGroups
        )
    }

    private func intValue(from value: Any?) -> Int? {
        if let int = value as? Int {
            return int
        }

        if let number = value as? NSNumber {
            return number.intValue
        }

        return nil
    }

    private func doubleValue(from value: Any?) -> Double? {
        if let double = value as? Double {
            return double
        }

        if let int = value as? Int {
            return Double(int)
        }

        if let number = value as? NSNumber {
            return number.doubleValue
        }

        return nil
    }
}
