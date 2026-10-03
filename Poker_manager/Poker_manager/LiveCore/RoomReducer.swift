import Foundation

/// Something an admin does to a live game.
nonisolated enum RoomAction: Equatable {
    /// `eventId` makes the action idempotent: replaying it (a retry, or the
    /// host's own echo) never adds a second buy-in.
    case buyIn(eventId: String, playerId: String, playerName: String, avatar: String, amount: Double)
    /// Mid-game cash-out. Calling it again for the same player replaces the amount.
    case cashOut(playerId: String, amount: Double)
    /// Final chip counts for players still at the table, then settle up.
    case endGame(finalCashOuts: [String: Double])
    case reopen
    case addAdmin(uid: String, name: String)
    case removeAdmin(uid: String)
}

nonisolated enum RoomActionError: LocalizedError, Equatable {
    case legacyRoom
    case notAdmin
    case notHost
    case gameEnded
    case unknownPlayer
    case invalidAmount
    case cannotRemoveHost

    var errorDescription: String? {
        switch self {
        case .legacyRoom: return "This game was started on an older version of the app. Ask the host to update."
        case .notAdmin: return "Only the game's admins can do that."
        case .notHost: return "Only the host can do that."
        case .gameEnded: return "This game has already ended."
        case .unknownPlayer: return "That player isn't in this game."
        case .invalidAmount: return "Enter a valid amount."
        case .cannotRemoveHost: return "The host can't be removed."
        }
    }
}

/// Pure state transitions for a live room. FirebaseService runs these inside
/// a Firestore transaction, so two admins tapping at once never overwrite
/// each other.
nonisolated enum RoomReducer {

    static func cashOutEventId(for playerId: String) -> String {
        "cashout-\(playerId)"
    }

    /// Returns the updated room, or the unchanged room when the action was
    /// already applied (so callers can skip the write).
    static func apply(_ action: RoomAction, to room: GameRoom, by uid: String, actorName: String?, at now: Date) throws -> GameRoom {
        guard room.supportsSharedControl else { throw RoomActionError.legacyRoom }
        guard room.isAdmin(uid) else { throw RoomActionError.notAdmin }

        var updated = room

        switch action {
        case let .buyIn(eventId, playerId, playerName, avatar, amount):
            guard room.isActive else { throw RoomActionError.gameEnded }
            guard amount.isFinite, amount > 0 else { throw RoomActionError.invalidAmount }
            if room.buyInTimeline.contains(where: { $0.id == eventId }) { return room }

            if let index = updated.players.firstIndex(where: { $0.id == playerId }) {
                updated.players[index].name = playerName
            } else {
                updated.players.append(PlayerSnapshot(id: playerId, name: playerName, avatar: avatar,
                                                      totalBuyIn: 0, buyInCount: 0, cashOut: nil, profitLoss: 0))
            }
            updated.buyInTimeline.append(BuyInEvent(id: eventId, playerName: playerName, timestamp: now,
                                                    amount: amount, cumulativeTotal: 0, isCashOut: false,
                                                    playerId: playerId, recordedBy: actorName))

        case let .cashOut(playerId, amount):
            guard room.isActive else { throw RoomActionError.gameEnded }
            guard amount.isFinite, amount >= 0 else { throw RoomActionError.invalidAmount }
            guard room.players.contains(where: { $0.id == playerId }) else { throw RoomActionError.unknownPlayer }
            if room.players.first(where: { $0.id == playerId })?.cashOut == amount { return room }
            setCashOut(&updated, playerId: playerId, amount: amount, at: now, actorName: actorName)

        case let .endGame(finalCashOuts):
            guard room.isActive else { throw RoomActionError.gameEnded }
            for playerId in finalCashOuts.keys.sorted() {
                let amount = finalCashOuts[playerId] ?? 0
                guard amount.isFinite, amount >= 0 else { throw RoomActionError.invalidAmount }
                guard room.players.contains(where: { $0.id == playerId }) else { throw RoomActionError.unknownPlayer }
                setCashOut(&updated, playerId: playerId, amount: amount, at: now, actorName: actorName)
            }
            updated.status = "completed"
            updated.endedAt = now

        case .reopen:
            if room.isActive { return room }
            updated.status = "active"
            updated.endedAt = nil
            updated.settlement = []

        case let .addAdmin(targetUid, name):
            if room.isAdmin(targetUid) && room.adminNames?[targetUid] == name { return room }
            var ids = room.adminIds ?? [room.hostId]
            if !ids.contains(targetUid) { ids.append(targetUid) }
            updated.adminIds = ids
            var names = room.adminNames ?? [:]
            names[targetUid] = name
            updated.adminNames = names

        case let .removeAdmin(targetUid):
            guard uid == room.hostId else { throw RoomActionError.notHost }
            guard targetUid != room.hostId else { throw RoomActionError.cannotRemoveHost }
            guard (room.adminIds ?? []).contains(targetUid) else { return room }
            updated.adminIds = (room.adminIds ?? []).filter { $0 != targetUid }
            updated.adminNames?[targetUid] = nil
        }

        recompute(&updated)
        if case .endGame = action {
            updated.settlement = SettlementCalculator.transfers(for: updated.players).map {
                SettlementEntry(from: $0.from, to: $0.to, amount: $0.amount)
            }
        }
        updated.updatedAt = now
        updated.updatedBy = uid
        return updated
    }

    /// Rebuilds pot, running totals and per-player numbers from the timeline,
    /// which is the only thing actions append to.
    static func recompute(_ room: inout GameRoom) {
        let ordered = room.buyInTimeline.enumerated().sorted { lhs, rhs in
            if lhs.element.timestamp != rhs.element.timestamp {
                return lhs.element.timestamp < rhs.element.timestamp
            }
            return lhs.offset < rhs.offset
        }.map(\.element)

        var cumulative = 0.0
        room.buyInTimeline = ordered.map { event in
            var event = event
            cumulative += event.isCashOut == true ? -event.amount : event.amount
            event.cumulativeTotal = cumulative
            return event
        }
        room.totalPot = cumulative

        room.players = room.players.map { player in
            var player = player
            let events = room.buyInTimeline.filter { $0.playerId == player.id }
            let buyIns = events.filter { $0.isCashOut != true }
            player.totalBuyIn = buyIns.reduce(0) { $0 + $1.amount }
            player.buyInCount = buyIns.count
            player.cashOut = events.last(where: { $0.isCashOut == true })?.amount
            player.profitLoss = (player.cashOut ?? 0) - player.totalBuyIn
            return player
        }
    }

    private static func setCashOut(_ room: inout GameRoom, playerId: String, amount: Double, at now: Date, actorName: String?) {
        let eventId = cashOutEventId(for: playerId)
        let name = room.players.first(where: { $0.id == playerId })?.name ?? "Unknown"
        room.buyInTimeline.removeAll { $0.id == eventId }
        room.buyInTimeline.append(BuyInEvent(id: eventId, playerName: name, timestamp: now,
                                             amount: amount, cumulativeTotal: 0, isCashOut: true,
                                             playerId: playerId, recordedBy: actorName))
    }
}
