import Foundation
import FirebaseFirestore

protocol CloudListenerToken {
    func remove()
}

final class FirestoreListenerToken: CloudListenerToken {
    private var registration: ListenerRegistration?

    init(registration: ListenerRegistration) {
        self.registration = registration
    }

    func remove() {
        registration?.remove()
        registration = nil
    }
}
