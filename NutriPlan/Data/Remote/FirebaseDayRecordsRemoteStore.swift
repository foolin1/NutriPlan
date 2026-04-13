import Foundation
import FirebaseFirestore

protocol DayRecordsRemoteStore {
    func fetchCurrentDay(uid: String) async throws -> PersistedPlanSession?
    func saveCurrentDay(_ session: PersistedPlanSession, uid: String) async throws
    func clearCurrentDay(uid: String) async throws

    func fetchHistory(uid: String) async throws -> [PlanHistoryRecord]
    func saveHistoryRecord(_ record: PlanHistoryRecord, uid: String) async throws

    func observeCurrentDay(
        uid: String,
        onChange: @escaping (Result<PersistedPlanSession?, Error>) -> Void
    ) -> CloudListenerToken

    func observeHistory(
        uid: String,
        onChange: @escaping (Result<[PlanHistoryRecord], Error>) -> Void
    ) -> CloudListenerToken
}

final class FirebaseDayRecordsRemoteStore: DayRecordsRemoteStore {
    private let db: Firestore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        db: Firestore = Firestore.firestore(),
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.db = db
        self.encoder = encoder
        self.decoder = decoder
    }

    func fetchCurrentDay(uid: String) async throws -> PersistedPlanSession? {
        let snapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DocumentSnapshot, Error>) in
            currentDayDocument(uid: uid).getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let snapshot else {
                    continuation.resume(throwing: NSError(
                        domain: "NutriPlan.Firestore",
                        code: -21,
                        userInfo: [NSLocalizedDescriptionKey: "Не удалось получить текущую дневную сессию."]
                    ))
                    return
                }

                continuation.resume(returning: snapshot)
            }
        }

        guard snapshot.exists, let data = snapshot.data() else {
            return nil
        }

        guard let payload = data["payload"] as? [String: Any] else {
            return nil
        }

        return try decode(PersistedPlanSession.self, from: payload)
    }

    func saveCurrentDay(_ session: PersistedPlanSession, uid: String) async throws {
        let payload = try encode(session)

        let document: [String: Any] = [
            "dayId": session.dayId,
            "savedAtUnix": session.savedAt.timeIntervalSince1970,
            "payload": payload
        ]

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            currentDayDocument(uid: uid).setData(document, merge: true) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func clearCurrentDay(uid: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            currentDayDocument(uid: uid).delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func fetchHistory(uid: String) async throws -> [PlanHistoryRecord] {
        let snapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QuerySnapshot, Error>) in
            historyCollection(uid: uid)
                .order(by: "dayId", descending: true)
                .getDocuments { snapshot, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let snapshot else {
                        continuation.resume(throwing: NSError(
                            domain: "NutriPlan.Firestore",
                            code: -22,
                            userInfo: [NSLocalizedDescriptionKey: "Не удалось получить архив дней."]
                        ))
                        return
                    }

                    continuation.resume(returning: snapshot)
                }
        }

        return try snapshot.documents.compactMap { document in
            guard let payload = document.data()["payload"] as? [String: Any] else {
                return nil
            }

            return try decode(PlanHistoryRecord.self, from: payload)
        }
    }

    func saveHistoryRecord(_ record: PlanHistoryRecord, uid: String) async throws {
        let payload = try encode(record)

        let document: [String: Any] = [
            "dayId": record.dayId,
            "savedAtUnix": record.savedAt.timeIntervalSince1970,
            "payload": payload
        ]

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            historyCollection(uid: uid)
                .document(record.dayId)
                .setData(document, merge: true) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
        }
    }

    func observeCurrentDay(
        uid: String,
        onChange: @escaping (Result<PersistedPlanSession?, Error>) -> Void
    ) -> CloudListenerToken {
        let registration = currentDayDocument(uid: uid).addSnapshotListener { snapshot, error in
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

            guard let payload = data["payload"] as? [String: Any] else {
                onChange(.success(nil))
                return
            }

            do {
                let session = try self.decode(PersistedPlanSession.self, from: payload)
                onChange(.success(session))
            } catch {
                onChange(.failure(error))
            }
        }

        return FirestoreListenerToken(registration: registration)
    }

    func observeHistory(
        uid: String,
        onChange: @escaping (Result<[PlanHistoryRecord], Error>) -> Void
    ) -> CloudListenerToken {
        let registration = historyCollection(uid: uid)
            .order(by: "dayId", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                guard let snapshot else {
                    onChange(.success([]))
                    return
                }

                do {
                    let records: [PlanHistoryRecord] = try snapshot.documents.compactMap { document in
                        guard let payload = document.data()["payload"] as? [String: Any] else {
                            return nil
                        }

                        return try self.decode(PlanHistoryRecord.self, from: payload)
                    }

                    onChange(.success(records))
                } catch {
                    onChange(.failure(error))
                }
            }

        return FirestoreListenerToken(registration: registration)
    }

    private func currentDayDocument(uid: String) -> DocumentReference {
        db.collection("users")
            .document(uid)
            .collection("dayState")
            .document("current")
    }

    private func historyCollection(uid: String) -> CollectionReference {
        db.collection("users")
            .document(uid)
            .collection("dayHistory")
    }

    private func encode<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try encoder.encode(value)
        let object = try JSONSerialization.jsonObject(with: data)

        guard let dictionary = object as? [String: Any] else {
            throw NSError(
                domain: "NutriPlan.Firestore",
                code: -23,
                userInfo: [NSLocalizedDescriptionKey: "Не удалось сериализовать данные для Firestore."]
            )
        }

        return dictionary
    }

    private func decode<T: Decodable>(_ type: T.Type, from dictionary: [String: Any]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try decoder.decode(type, from: data)
    }
}
