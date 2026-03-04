
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
    
    // Group state
    @Published var userGroups: [PokerGroup] = []
    @Published var activeGroup: PokerGroup?
    
    // MARK: - Private
    private let db = Firestore.firestore()
    private var roomListener: ListenerRegistration?
    private var groupListener: ListenerRegistration?
    private var groupsListener: ListenerRegistration?
    
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
    
    /// Generate a unique 6-digit room code
    private func generateRoomCode() -> String {
        let code = String(format: "%06d", Int.random(in: 100000...999999))
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
    
    // MARK: - Group Code Generation
    
    /// Generate a 6-char alphanumeric group code like "A3F29X"
    private func generateGroupCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // no I/O/0/1 for clarity
        return String((0..<6).map { _ in chars.randomElement()! })
    }
    
    // MARK: - Group: Create
    
    /// Create a new poker group
    func createGroup(name: String, displayName: String, currency: CurrencyOption = .ILS, defaultBuyIn: Double? = nil, completion: @escaping (Result<PokerGroup, Error>) -> Void) {
        guard let userId = currentUserId else {
            completion(.failure(FirebaseServiceError.notAuthenticated))
            return
        }
        
        let code = generateGroupCode()
        var group = PokerGroup(groupId: code, name: name, createdBy: userId, currency: currency, defaultBuyIn: defaultBuyIn)
        group.memberNames[userId] = displayName
        
        let docRef = db.collection("groups").document(code)
        docRef.getDocument { [weak self] snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                // Code collision — retry
                self?.createGroup(name: name, displayName: displayName, completion: completion)
                return
            }
            
            do {
                try docRef.setData(from: group) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            self?.userGroups.append(group)
                            self?.activeGroup = group
                            self?.listenToGroup(groupId: code)
                            completion(.success(group))
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
    
    // MARK: - Group: Join
    
    /// Join an existing group by code
    func joinGroup(code: String, displayName: String, completion: @escaping (Result<PokerGroup, Error>) -> Void) {
        guard let userId = currentUserId else {
            completion(.failure(FirebaseServiceError.notAuthenticated))
            return
        }
        
        let docRef = db.collection("groups").document(code.uppercased())
        docRef.getDocument(as: PokerGroup.self) { [weak self] result in
            switch result {
            case .success(var group):
                if group.memberIds.contains(userId) {
                    // Already a member
                    DispatchQueue.main.async {
                        self?.activeGroup = group
                        self?.listenToGroup(groupId: code.uppercased())
                        completion(.success(group))
                    }
                    return
                }
                
                // Add user to group
                group.memberIds.append(userId)
                group.memberNames[userId] = displayName
                
                do {
                    try docRef.setData(from: group, merge: true) { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                self?.userGroups.append(group)
                                self?.activeGroup = group
                                self?.listenToGroup(groupId: code.uppercased())
                                completion(.success(group))
                            }
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
                
            case .failure:
                DispatchQueue.main.async {
                    completion(.failure(FirebaseServiceError.groupNotFound))
                }
            }
        }
    }
    
    // MARK: - Group: Leave
    
    /// Leave the active group
    func leaveGroup(groupId: String) {
        guard let userId = currentUserId else { return }
        
        let docRef = db.collection("groups").document(groupId)
        docRef.updateData([
            "memberIds": FieldValue.arrayRemove([userId]),
            "memberNames.\(userId)": FieldValue.delete()
        ])
        
        stopGroupListener()
        DispatchQueue.main.async {
            self.userGroups.removeAll { $0.groupId == groupId }
            if self.activeGroup?.groupId == groupId {
                self.activeGroup = nil
            }
        }
    }
    
    // MARK: - Group: Delete (Host only)
    
    /// Delete the entire group (must be the creator)
    func deleteGroup(groupId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = currentUserId else {
            completion(.failure(FirebaseServiceError.notAuthenticated))
            return
        }
        
        let docRef = db.collection("groups").document(groupId)
        docRef.getDocument(as: PokerGroup.self) { [weak self] result in
            switch result {
            case .success(let group):
                guard group.createdBy == userId else {
                    completion(.failure(FirebaseServiceError.notAuthorized))
                    return
                }
                docRef.delete { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            self?.stopGroupListener()
                            self?.userGroups.removeAll { $0.groupId == groupId }
                            if self?.activeGroup?.groupId == groupId {
                                self?.activeGroup = nil
                            }
                            completion(.success(()))
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Group: Remove Member (Host only)
    
    /// Remove a member from the group (must be the creator)
    func removeMember(groupId: String, memberUid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = currentUserId else {
            completion(.failure(FirebaseServiceError.notAuthenticated))
            return
        }
        
        let docRef = db.collection("groups").document(groupId)
        docRef.getDocument(as: PokerGroup.self) { result in
            switch result {
            case .success(let group):
                guard group.createdBy == userId else {
                    completion(.failure(FirebaseServiceError.notAuthorized))
                    return
                }
                guard memberUid != userId else {
                    // Can't remove yourself — use leaveGroup instead
                    completion(.failure(FirebaseServiceError.notAuthorized))
                    return
                }
                docRef.updateData([
                    "memberIds": FieldValue.arrayRemove([memberUid]),
                    "memberNames.\(memberUid)": FieldValue.delete()
                ]) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Group: Load User's Groups
    
    /// Load all groups the current user belongs to
    func loadUserGroups() {
        guard let userId = currentUserId else { return }
        
        stopGroupsListener()
        
        groupsListener = db.collection("groups")
            .whereField("memberIds", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let groups = documents.compactMap { doc in
                    try? doc.data(as: PokerGroup.self)
                }
                
                DispatchQueue.main.async {
                    self?.userGroups = groups
                }
            }
    }
    
    // MARK: - Group: Real-time Listener
    
    /// Listen to real-time updates for a specific group
    func listenToGroup(groupId: String) {
        stopGroupListener()
        
        groupListener = db.collection("groups").document(groupId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot, data.exists else { return }
                
                do {
                    let group = try data.data(as: PokerGroup.self)
                    DispatchQueue.main.async {
                        self?.activeGroup = group
                        // Also update in the list
                        if let index = self?.userGroups.firstIndex(where: { $0.groupId == groupId }) {
                            self?.userGroups[index] = group
                        }
                    }
                } catch {
                    print("Failed to decode group update: \(error)")
                }
            }
    }
    
    /// Stop group listener
    private func stopGroupListener() {
        groupListener?.remove()
        groupListener = nil
    }
    
    /// Stop groups list listener
    private func stopGroupsListener() {
        groupsListener?.remove()
        groupsListener = nil
    }
}

// MARK: - Errors

enum FirebaseServiceError: LocalizedError {
    case notAuthenticated
    case notAuthorized
    case roomNotFound
    case roomExpired
    case groupNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in. Please restart the app."
        case .notAuthorized:
            return "You don't have permission to perform this action."
        case .roomNotFound:
            return "Room not found. Check the code and try again."
        case .roomExpired:
            return "This game room has expired."
        case .groupNotFound:
            return "Group not found. Check the code and try again."
        }
    }
}
