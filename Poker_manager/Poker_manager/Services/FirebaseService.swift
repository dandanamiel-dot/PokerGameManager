
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
    /// Host or co-admin: can record buy-ins, cash-outs and end the game
    @Published var isAdmin = false
    /// False while showing cached data (offline or reconnecting)
    @Published var isLive = false
    /// Everyone who has opened the room (see activeViewers)
    @Published var viewers: [ViewerPresence] = []
    @Published var connectionError: String?
    /// Last admin action the room rejected, for an alert
    @Published var actionError: String?
    /// Live games in the current group that you can join without a code
    @Published var groupLiveRooms: [GameRoom] = []
    
    // Group state
    @Published var userGroups: [PokerGroup] = []
    @Published var activeGroup: PokerGroup?
    
    // MARK: - Private
    private let db = Firestore.firestore()
    private var roomListener: ListenerRegistration?
    private var groupListener: ListenerRegistration?
    private var groupsListener: ListenerRegistration?
    private var viewersListener: ListenerRegistration?
    private var groupRoomsListener: ListenerRegistration?
    private var presenceTimer: Timer?
    private var presenceRef: DocumentReference?
    private var pendingActions: [RoomAction] = []
    private var isFlushing = false
    
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
    
    /// Name shown to other people in a room: your group name, else what you
    /// typed when joining, else "Guest".
    func displayName(for uid: String? = nil) -> String {
        let uid = uid ?? currentUserId
        if let uid, let name = activeGroup?.memberNames[uid], !name.isEmpty {
            return name
        }
        if let name = UserDefaults.standard.string(forKey: Self.liveDisplayNameKey), !name.isEmpty {
            return name
        }
        return "Guest"
    }
    
    static let liveDisplayNameKey = "liveDisplayName"
    private static let lastJoinedRoomKey = "lastJoinedRoomCode"
    
    // MARK: - Host: Create Room
    
    /// Host creates a new room from their active GameSession
    func createRoom(from session: GameSession, currencySymbol: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        guard let hostId = currentUserId else {
            completion(.failure(FirebaseServiceError.notAuthenticated))
            return
        }
        
        let code = generateRoomCode()
        var room = GameRoom.from(session: session, roomCode: code, hostId: hostId)
        room.groupId = session.groupId == "local" ? nil : session.groupId
        room.currencySymbol = currencySymbol
        room.adminNames = [hostId: displayName(for: hostId)]
        room.updatedAt = Date()
        room.updatedBy = hostId
        
        // Check if code already exists, retry if so
        let docRef = db.collection("rooms").document(code)
        docRef.getDocument { [weak self] snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                // Code collision — retry with new code
                self?.createRoom(from: session, currencySymbol: currencySymbol, completion: completion)
                return
            }
            
            // Write room to Firestore
            do {
                try docRef.setData(from: room) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            self?.attach(to: room)
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
    
    // MARK: - Admin Actions
    
    /// Apply an action (buy-in, cash-out, end game, admin change) to the live
    /// room inside a transaction, so simultaneous admins never overwrite each
    /// other. Network failures are queued and retried when the connection
    /// comes back; actions are idempotent so retrying is safe.
    func perform(_ action: RoomAction, completion: ((Error?) -> Void)? = nil) {
        guard let code = roomCode, let uid = currentUserId else {
            completion?(FirebaseServiceError.notAuthenticated)
            return
        }
        
        let ref = db.collection("rooms").document(code)
        let actorName = displayName(for: uid)
        let actionError = ErrorBox()
        
        db.runTransaction({ @Sendable transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(ref)
                let room = try snapshot.data(as: GameRoom.self)
                let updated = try RoomReducer.apply(action, to: room, by: uid, actorName: actorName, at: Date())
                if updated != room {
                    try transaction.setData(from: updated, forDocument: ref)
                }
            } catch let error as RoomActionError {
                actionError.error = error
                errorPointer?.pointee = error as NSError
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }) { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let rejected = actionError.error {
                    // The room said no (not an admin, game over...). Don't retry.
                    self.actionError = rejected.localizedDescription
                    completion?(rejected)
                } else if let error, Self.isRetryable(error) {
                    // Offline or contended: keep it and retry when the room is reachable
                    if !self.pendingActions.contains(action) {
                        self.pendingActions.append(action)
                    }
                    self.isLive = false
                    completion?(error)
                } else if let error {
                    self.actionError = error.localizedDescription
                    completion?(error)
                } else {
                    completion?(nil)
                }
            }
        }
    }
    
    var hasPendingActions: Bool { !pendingActions.isEmpty }
    
    private static func isRetryable(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == FirestoreErrorDomain else { return false }
        let retryable: [FirestoreErrorCode.Code] = [.unavailable, .deadlineExceeded, .aborted, .resourceExhausted]
        return retryable.map(\.rawValue).contains(nsError.code)
    }
    
    /// Retry actions that failed while offline.
    private func flushPendingActions() {
        guard !pendingActions.isEmpty, !isFlushing else { return }
        isFlushing = true
        let queued = pendingActions
        pendingActions = []
        let group = DispatchGroup()
        for action in queued {
            group.enter()
            perform(action) { _ in group.leave() }
        }
        group.notify(queue: .main) { [weak self] in
            self?.isFlushing = false
        }
    }
    
    /// Make another person in the room an admin.
    func makeAdmin(_ viewer: ViewerPresence, completion: ((Error?) -> Void)? = nil) {
        perform(.addAdmin(uid: viewer.uid, name: viewer.name), completion: completion)
    }
    
    /// Take admin rights away (host only).
    func removeAdmin(uid: String, completion: ((Error?) -> Void)? = nil) {
        perform(.removeAdmin(uid: uid), completion: completion)
    }
    
    // MARK: - Join Room
    
    /// Join a room by code. Works for viewers, co-admins, and a host
    /// reconnecting after the app restarted.
    func joinRoom(code: String, completion: @escaping (Result<GameRoom, Error>) -> Void) {
        let docRef = db.collection("rooms").document(code)
        
        docRef.getDocument(as: GameRoom.self) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let room):
                    self?.attach(to: room)
                    if room.hostId != self?.currentUserId {
                        UserDefaults.standard.set(code, forKey: Self.lastJoinedRoomKey)
                    }
                    completion(.success(room))
                case .failure:
                    completion(.failure(FirebaseServiceError.roomNotFound))
                }
            }
        }
    }
    
    /// Reconnect to the last game you were watching, if it's still running.
    func rejoinLastRoomIfNeeded() {
        guard activeRoom == nil,
              let code = UserDefaults.standard.string(forKey: Self.lastJoinedRoomKey) else { return }
        joinRoom(code: code) { [weak self] result in
            switch result {
            case .success(let room):
                if !room.isActive || Date().timeIntervalSince(room.lastActivity) > Self.staleRoomAge {
                    self?.leaveRoom()
                }
            case .failure:
                UserDefaults.standard.removeObject(forKey: Self.lastJoinedRoomKey)
            }
        }
    }
    
    /// Rooms with no activity for this long are treated as abandoned.
    static let staleRoomAge: TimeInterval = 12 * 60 * 60
    
    private func attach(to room: GameRoom) {
        activeRoom = room
        roomCode = room.roomCode
        updateRoles(for: room)
        connectionError = nil
        actionError = nil
        listenToRoom(code: room.roomCode)
        startPresence(code: room.roomCode)
    }
    
    private func updateRoles(for room: GameRoom) {
        isHost = room.hostId == currentUserId
        isAdmin = room.isAdmin(currentUserId)
    }
    
    // MARK: - Real-time Listener
    
    /// Subscribe to real-time updates for a room
    private func listenToRoom(code: String) {
        stopListening()
        
        let docRef = db.collection("rooms").document(code)
        roomListener = docRef.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            guard let self else { return }
            if error != nil {
                DispatchQueue.main.async { self.isLive = false }
                return
            }
            guard let snapshot else { return }
            let fromCache = snapshot.metadata.isFromCache
            
            guard snapshot.exists else {
                if !fromCache {
                    DispatchQueue.main.async {
                        self.connectionError = "This game room was closed"
                    }
                }
                return
            }
            
            do {
                let room = try snapshot.data(as: GameRoom.self)
                DispatchQueue.main.async {
                    guard self.roomCode == code else { return }
                    self.activeRoom = room
                    self.updateRoles(for: room)
                    self.isLive = !fromCache
                    self.connectionError = nil
                    if !fromCache {
                        self.flushPendingActions()
                    }
                }
            } catch {
                print("Failed to decode room update: \(error)")
            }
        }
    }
    
    // MARK: - Presence
    
    /// Announce yourself in the room and keep a heartbeat going, and watch
    /// who else is there.
    private func startPresence(code: String) {
        stopPresence()
        guard let uid = currentUserId else { return }
        
        let viewersRef = db.collection("rooms").document(code).collection("viewers")
        let myRef = viewersRef.document(uid)
        let heartbeat: () -> Void = { [weak self] in
            myRef.setData([
                "uid": uid,
                "name": self?.displayName(for: uid) ?? "Guest",
                "lastSeen": FieldValue.serverTimestamp()
            ])
        }
        heartbeat()
        presenceTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            DispatchQueue.main.async { heartbeat() }
        }
        presenceRef = myRef
        
        viewersListener = viewersRef.addSnapshotListener { [weak self] snapshot, _ in
            let viewers = snapshot?.documents.compactMap { try? $0.data(as: ViewerPresence.self) } ?? []
            DispatchQueue.main.async {
                self?.viewers = viewers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
        }
    }
    
    private func stopPresence(removeSelf: Bool = false) {
        presenceTimer?.invalidate()
        presenceTimer = nil
        viewersListener?.remove()
        viewersListener = nil
        if removeSelf {
            presenceRef?.delete()
        }
        presenceRef = nil
    }
    
    /// People seen in the room recently.
    var activeViewers: [ViewerPresence] {
        let now = Date()
        return viewers.filter { $0.isActive(at: now) }
    }
    
    // MARK: - Group Live Games
    
    /// Watch for live games in a group so members can join without a code.
    func listenToGroupRooms(groupId: String) {
        stopGroupRoomsListener()
        guard groupId != "local" else {
            groupLiveRooms = []
            return
        }
        groupRoomsListener = db.collection("rooms")
            .whereField("groupId", isEqualTo: groupId)
            .whereField("status", isEqualTo: "active")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("Failed to load live group games: \(error)")
                }
                let now = Date()
                let rooms = (snapshot?.documents ?? [])
                    .compactMap { try? $0.data(as: GameRoom.self) }
                    .filter { $0.isActive && now.timeIntervalSince($0.lastActivity) < Self.staleRoomAge }
                    .sorted { $0.lastActivity > $1.lastActivity }
                DispatchQueue.main.async {
                    self?.groupLiveRooms = rooms
                }
            }
    }
    
    func stopGroupRoomsListener() {
        groupRoomsListener?.remove()
        groupRoomsListener = nil
    }
    
    // MARK: - Cleanup
    
    /// Stop listening and leave the room
    func leaveRoom() {
        stopListening()
        stopPresence(removeSelf: true)
        UserDefaults.standard.removeObject(forKey: Self.lastJoinedRoomKey)
        DispatchQueue.main.async {
            self.activeRoom = nil
            self.roomCode = nil
            self.isHost = false
            self.isAdmin = false
            self.isLive = false
            self.viewers = []
            self.pendingActions = []
            self.connectionError = nil
            self.actionError = nil
        }
    }
    
    /// Stop the Firestore listener
    private func stopListening() {
        roomListener?.remove()
        roomListener = nil
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
                
                // Add yourself with a field update so nothing else in the
                // group document is rewritten (the security rules check this)
                group.memberIds.append(userId)
                group.memberNames[userId] = displayName
                
                docRef.updateData([
                    "memberIds": FieldValue.arrayUnion([userId]),
                    "memberNames.\(userId)": displayName
                ]) { error in
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

/// Carries a rejected action out of the Firestore transaction block.
nonisolated final class ErrorBox: @unchecked Sendable {
    var error: RoomActionError?
}
