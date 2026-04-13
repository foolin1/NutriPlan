import Foundation
import FirebaseFirestore

protocol ProfileSnapshotsRemoteStore {
    func fetchSnapshots(uid: String) async throws -> [ProfileSnapshot]
    func appendSnapshot(_ profile: UserProfile, uid: String) async throws
    func observeSnapshots(
        uid: String,
        onChange: @escaping (Result<[ProfileSnapshot], Error>) -> Void
    ) -> CloudListenerToken
}

final class FirebaseProfileSnapshotsRemoteStore: ProfileSnapshotsRemoteStore {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func fetchSnapshots(uid: String) async throws -> [ProfileSnapshot] {
        let querySnapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QuerySnapshot, Error>) in
            snapshotsCollection(uid: uid)
                .order(by: "recordedAt", descending: true)
                .getDocuments { snapshot, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let snapshot else {
                        continuation.resume(throwing: NSError(
                            domain: "NutriPlan.Firestore",
                            code: -11,
                            userInfo: [NSLocalizedDescriptionKey: "Не удалось получить историю снимков профиля."]
                        ))
                        return
                    }

                    continuation.resume(returning: snapshot)
                }
        }

        return querySnapshot.documents.compactMap { document in
            mapSnapshot(documentID: document.documentID, data: document.data())
        }
    }

    func appendSnapshot(_ profile: UserProfile, uid: String) async throws {
        let payload = makePayload(from: profile)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            snapshotsCollection(uid: uid).addDocument(data: payload) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func observeSnapshots(
        uid: String,
        onChange: @escaping (Result<[ProfileSnapshot], Error>) -> Void
    ) -> CloudListenerToken {
        let registration = snapshotsCollection(uid: uid)
            .order(by: "recordedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                guard let snapshot else {
                    onChange(.success([]))
                    return
                }

                let items = snapshot.documents.compactMap { document in
                    self.mapSnapshot(documentID: document.documentID, data: document.data())
                }

                onChange(.success(items))
            }

        return FirestoreListenerToken(registration: registration)
    }

    private func snapshotsCollection(uid: String) -> CollectionReference {
        db.collection("users")
            .document(uid)
            .collection("profileSnapshots")
    }

    private func makePayload(from profile: UserProfile) -> [String: Any] {
        [
            "sex": profile.sex.rawValue,
            "age": profile.age,
            "heightCm": profile.heightCm,
            "weightKg": profile.weightKg,
            "activityLevel": profile.activityLevel.rawValue,
            "goalType": profile.goalType.rawValue,
            "nutrientFocus": profile.nutrientFocus.displayName,
            "excludedAllergens": profile.excludedAllergens,
            "excludedProducts": profile.excludedProducts,
            "excludedGroups": profile.excludedGroups,
            "recordedAt": FieldValue.serverTimestamp()
        ]
    }

    private func mapSnapshot(documentID: String, data: [String: Any]) -> ProfileSnapshot? {
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

        let nutrientFocusName = data["nutrientFocus"] as? String ?? NutrientFocus.none.displayName
        let nutrientFocus = NutrientFocus.allCases.first(where: { $0.displayName == nutrientFocusName }) ?? .none

        let excludedAllergens = data["excludedAllergens"] as? [String] ?? []
        let excludedProducts = data["excludedProducts"] as? [String] ?? []
        let excludedGroups = data["excludedGroups"] as? [String] ?? []

        let profile = UserProfile(
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

        let recordedAt: Date
        if let timestamp = data["recordedAt"] as? Timestamp {
            recordedAt = timestamp.dateValue()
        } else {
            recordedAt = .distantPast
        }

        return ProfileSnapshot(
            id: documentID,
            recordedAt: recordedAt,
            profile: profile
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
