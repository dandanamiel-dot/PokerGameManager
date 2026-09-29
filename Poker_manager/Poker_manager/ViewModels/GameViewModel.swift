
import SwiftUI
import SwiftData
import Combine

class GameViewModel: ObservableObject {
    @Published var activeSession: GameSession
    @Published var availablePlayers: [Player] = []
    @Published var showSettlementView = false
    @Published var saveError: String?        // Issue 6: surfaced to views for alert

    private var modelContext: ModelContext
    private let groupId: String
    
    init(modelContext: ModelContext, session: GameSession) {
        self.modelContext = modelContext
        self.activeSession = session
        self.groupId = session.groupId
        fetchPlayers()
    }
    
    func fetchPlayers() {
        let gId = groupId
        do {
            let descriptor = FetchDescriptor<Player>(
                predicate: #Predicate { $0.groupId == gId }
            )
            availablePlayers = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch players: \(error)")
        }
    }
    
    func addBuyIn(player: Player, amount: Double) {
        let buyIn: BuyIn
        if let existingSession = activeSession.playerSessions.first(where: { $0.player?.id == player.id }) {
            buyIn = existingSession.addBuyIn(amount: amount)
        } else {
            let newSession = PlayerSession(player: player)
            buyIn = newSession.addBuyIn(amount: amount)
            activeSession.playerSessions.append(newSession)
            modelContext.insert(newSession)
        }
        saveContext()
        objectWillChange.send()
        publish(.buyIn(eventId: buyIn.id.uuidString, playerId: roomPlayerId(for: player),
                       playerName: player.name, avatar: player.avatar, amount: amount))
    }
    
    /// Ends the game. Players with a draft cash-out from the end-game sheet
    /// are sent to the live room as their final chip counts.
    func calculateSettlements() {
        activeSession.status = .completed
        activeSession.endedAt = Date()
        saveContext()
        
        var finalCashOuts: [String: Double] = [:]
        for ps in activeSession.playerSessions where ps.cashOutTime == nil {
            if let player = ps.player, let cashOut = ps.cashOut {
                finalCashOuts[roomPlayerId(for: player)] = cashOut
            }
        }
        publish(.endGame(finalCashOuts: finalCashOuts))
    }
    
    func reopenGame() {
        activeSession.status = .active
        activeSession.endedAt = nil
        saveContext()
        objectWillChange.send()
        publish(.reopen)
    }
    
    /// Cash out a player mid-game
    func cashOutPlayer(session: PlayerSession, amount: Double) {
        session.cashOut = amount
        session.cashOutTime = Date()
        saveContext()
        objectWillChange.send()
        if let player = session.player {
            publish(.cashOut(playerId: roomPlayerId(for: player), amount: amount))
        }
    }
    
    // MARK: - Live room
    
    /// Remember which room this game is shared in.
    func attachRoom(code: String) {
        activeSession.roomCode = code
        saveContext()
    }
    
    /// Send a local change to the live room, if this game is shared.
    private func publish(_ action: RoomAction) {
        let firebase = FirebaseService.shared
        guard let code = activeSession.roomCode, firebase.roomCode == code, firebase.isAdmin else { return }
        firebase.perform(action)
    }
    
    /// The id this player has in the live room. Usually the local player id,
    /// but a player a co-admin added by name has the co-admin's id.
    private func roomPlayerId(for player: Player) -> String {
        let localId = player.id.uuidString
        guard let room = FirebaseService.shared.activeRoom, room.roomCode == activeSession.roomCode else { return localId }
        if room.players.contains(where: { $0.id == localId }) { return localId }
        return room.players.first(where: { $0.name.caseInsensitiveCompare(player.name) == .orderedSame })?.id ?? localId
    }
    
    /// Bring in changes a co-admin made on another phone. Our own writes are
    /// already applied locally, so snapshots we wrote are skipped.
    func mergeRemote(_ room: GameRoom, currentUserId: String?) {
        // While our own changes are still queued, the room is behind us;
        // wait for them to land rather than merging an older state.
        guard !FirebaseService.shared.hasPendingActions,
              room.supportsSharedControl,
              room.roomCode == activeSession.roomCode,
              let author = room.updatedBy, author != currentUserId else { return }
        
        var changed = false
        let knownBuyInIds = Set(activeSession.playerSessions.flatMap { $0.buyIns.map { $0.id.uuidString } })
        
        for event in room.buyInTimeline where event.isCashOut != true && !knownBuyInIds.contains(event.id) {
            guard let playerId = event.playerId,
                  let snapshot = room.players.first(where: { $0.id == playerId }) else { continue }
            let ps = localPlayerSession(for: snapshot)
            let buyIn = ps.addBuyIn(amount: event.amount)
            buyIn.id = UUID(uuidString: event.id) ?? UUID()
            buyIn.timestamp = event.timestamp
            changed = true
        }
        
        for snapshot in room.players {
            guard snapshot.cashOut != nil, let ps = existingPlayerSession(for: snapshot), ps.cashOut != snapshot.cashOut else { continue }
            ps.cashOut = snapshot.cashOut
            let event = room.buyInTimeline.first { $0.id == RoomReducer.cashOutEventId(for: snapshot.id) }
            if let event, room.endedAt.map({ event.timestamp < $0 }) ?? true {
                ps.cashOutTime = event.timestamp
            } else {
                ps.cashOutTime = nil
            }
            changed = true
        }
        
        if !room.isActive && activeSession.status == .active {
            activeSession.status = .completed
            activeSession.endedAt = room.endedAt ?? Date()
            changed = true
        } else if room.isActive && activeSession.status == .completed {
            activeSession.status = .active
            activeSession.endedAt = nil
            changed = true
        }
        
        if changed {
            saveContext()
            objectWillChange.send()
        }
    }
    
    private func existingPlayerSession(for snapshot: PlayerSnapshot) -> PlayerSession? {
        activeSession.playerSessions.first { $0.player?.id.uuidString == snapshot.id }
            ?? activeSession.playerSessions.first { $0.player?.name.caseInsensitiveCompare(snapshot.name) == .orderedSame }
    }
    
    private func localPlayerSession(for snapshot: PlayerSnapshot) -> PlayerSession {
        if let existing = existingPlayerSession(for: snapshot) { return existing }
        
        let player: Player
        if let known = availablePlayers.first(where: { $0.id.uuidString == snapshot.id })
            ?? availablePlayers.first(where: { $0.name.caseInsensitiveCompare(snapshot.name) == .orderedSame }) {
            player = known
        } else {
            player = Player(name: snapshot.name, avatar: snapshot.avatar, groupId: groupId)
            player.id = UUID(uuidString: snapshot.id) ?? UUID()
            modelContext.insert(player)
            availablePlayers.append(player)
        }
        
        let session = PlayerSession(player: player)
        activeSession.playerSessions.append(session)
        modelContext.insert(session)
        return session
    }

    // MARK: - Issue 6: Safe save helper
    /// Saves the model context, logging errors and surfacing them via `saveError`.
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            let msg = "Failed to save game data: \(error.localizedDescription)"
            print("⚠️ SwiftData save error: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.saveError = msg
            }
        }
    }

    struct SettlementTransaction: Identifiable {
        let id = UUID()
        let from: String
        let to: String
        let amount: Double
    }
    
    func generateTransactions() -> [SettlementTransaction] {
        let balances = activeSession.playerSessions.map { (name: $0.player?.name ?? "Unknown", amount: $0.profitLoss) }
        return SettlementCalculator.transfers(balances: balances).map {
            SettlementTransaction(from: $0.from, to: $0.to, amount: $0.amount)
        }
    }
}
