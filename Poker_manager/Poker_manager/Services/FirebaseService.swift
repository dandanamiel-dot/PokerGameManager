
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Central service handling Firebase room creation, joining, syncing, and cleanup.
class FirebaseService: ObservableObject {
    
    static let shared = FirebaseService()
    
    // MARK: - Published State
    @Published var currentUserId: String?
    @Published var isAuthenticated = false
    @Published var activeRoom: GameRoom?
    @Published var roomCode: String?
    @Published var isHost = false
    @Published var viewerCount: Int = 0
    @Published var connectionError: String?
    
    // MARK: - Private
    private let db = Firestore.firestore()
    private var roomListener: ListenerRegistration?
    
    private init() {
        signInAnonymously()
    }
    
    // MARK: - Authentication
    
    /// Sign in anonymously — no user input needed
    func signInAnonymously() {
        if let user = Auth.auth().currentUser {
            self.currentUserId = user.uid
            self.isAuthenticated = true
            return
        }
        
        Auth.auth().signInAnonymously { [weak self] result, error in
            DispatchQueue.main.async {
                if let user = result?.user {
                    self?.currentUserId = user.uid
                    self?.isAuthenticated = true
                } else {
                    self?.connectionError = error?.localizedDescription ?? "Authentication failed"
                }
            }
        }
    }
    
    // MARK: - Room Code Generation
    
    /// Generate a unique 4-digit room code
    private func generateRoomCode() -> String {
        let code = String(format: "%04d", Int.random(in: 1000...9999))
        return code
    }
    
    // MARK: - Host: Create Room
    
    /// Host creates a new room from their active GameSession
    func createRoom(from session: GameSession, completion: @escaping (Result<String, Error>) -> Void) {
        guard let hostId = currentUserId else {
            completion(.failure(FirebaseServiceError.notAuthenticated))
            return
        }
        
        let code = generateRoomCode()
        let room = GameRoom.from(session: session, roomCode: code, hostId: hostId)
        
        // Check if code already exists, retry if so
        let docRef = db.collection("rooms").document(code)
        docRef.getDocument { [weak self] snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                // Code collision — retry with new code
                self?.createRoom(from: session, completion: completion)
                return
            }
            
            // Write room to Firestore
            do {
                try docRef.setData(from: room) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            self?.roomCode = code
                            self?.isHost = true
                            self?.activeRoom = room
                            self?.listenToRoom(code: code)
                            completion(.success(code))
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Host: Sync Room
    
    /// Push updated game state to Firestore (called after buy-in, cash-out, end game)
    func syncRoom(from session: GameSession) {
        guard let code = roomCode, isHost, let hostId = currentUserId else { return }
        
        let room = GameRoom.from(session: session, roomCode: code, hostId: hostId)
        let docRef = db.collection("rooms").document(code)
        
        do {
            try docRef.setData(from: room, merge: true)
            DispatchQueue.main.async {
                self.activeRoom = room
            }
        } catch {
            print("Failed to sync room: \(error)")
        }
    }
    
    /// Push settlement data to the room
    func syncSettlement(transactions: [(from: String, to: String, amount: Double)]) {
        guard let code = roomCode, isHost else { return }
        
        let entries = transactions.map { t in
            SettlementEntry(from: t.from, to: t.to, amount: t.amount)
        }
        
        let docRef = db.collection("rooms").document(code)
        do {
            try docRef.updateData([
                "status": "completed",
                "settlement": entries.map { entry in
                    [
                        "id": entry.id,
                        "from": entry.from,
                        "to": entry.to,
                        "amount": entry.amount
                    ] as [String: Any]
                }
            ])
        } catch {
            print("Failed to sync settlement: \(error)")
        }
    }
    
    // MARK: - Viewer: Join Room
    
    /// Viewer joins a room by entering a code
    func joinRoom(code: String, completion: @escaping (Result<GameRoom, Error>) -> Void) {
        let docRef = db.collection("rooms").document(code)
        
        docRef.getDocument(as: GameRoom.self) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let room):
                    self?.activeRoom = room
                    self?.roomCode = code
                    self?.isHost = false
                    self?.listenToRoom(code: code)
                    completion(.success(room))
                case .failure(let error):
                    completion(.failure(FirebaseServiceError.roomNotFound))
                    _ = error // suppress unused warning
                }
            }
        }
    }
    
    // MARK: - Real-time Listener
    
    /// Subscribe to real-time updates for a room
    private func listenToRoom(code: String) {
        stopListening()
        
        let docRef = db.collection("rooms").document(code)
        roomListener = docRef.addSnapshotListener { [weak self] snapshot, error in
            guard let data = snapshot, data.exists else {
                DispatchQueue.main.async {
                    self?.connectionError = "Room no longer exists"
                }
                return
            }
            
            do {
                let room = try data.data(as: GameRoom.self)
                DispatchQueue.main.async {
                    self?.activeRoom = room
                }
            } catch {
                print("Failed to decode room update: \(error)")
            }
        }
    }
    
    // MARK: - Cleanup
    
    /// Stop listening and leave the room
    func leaveRoom() {
        stopListening()
        DispatchQueue.main.async {
            self.activeRoom = nil
            self.roomCode = nil
            self.isHost = false
            self.connectionError = nil
        }
    }
    
    /// Stop the Firestore listener
    private func stopListening() {
        roomListener?.remove()
        roomListener = nil
    }
    
    /// Delete the room (host only, after game ends)
    func deleteRoom() {
        guard let code = roomCode, isHost else { return }
        db.collection("rooms").document(code).delete()
        leaveRoom()
    }
}

// MARK: - Errors

enum FirebaseServiceError: LocalizedError {
    case notAuthenticated
    case roomNotFound
    case roomExpired
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in. Please restart the app."
        case .roomNotFound:
            return "Room not found. Check the code and try again."
        case .roomExpired:
            return "This game room has expired."
        }
    }
}
