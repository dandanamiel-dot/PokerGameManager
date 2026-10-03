import Foundation

// The room models themselves live in LiveCore/RoomModels.swift.

// MARK: - Conversion from local SwiftData models

extension GameRoom {

    /// Build a GameRoom snapshot from a local GameSession. Event ids match the
    /// local BuyIn ids so later actions and remote merges line up with them.
    static func from(session: GameSession, roomCode: String, hostId: String) -> GameRoom {
        var room = GameRoom(roomCode: roomCode, hostId: hostId, createdAt: session.date)
        room.status = session.status == .completed ? "completed" : "active"
        room.endedAt = session.endedAt

        var events: [BuyInEvent] = []

        for ps in session.playerSessions {
            let playerId = ps.player?.id.uuidString ?? ps.id.uuidString
            let name = ps.player?.name ?? "Unknown"

            room.players.append(PlayerSnapshot(
                id: playerId,
                name: name,
                avatar: ps.player?.avatar ?? "person.crop.circle.fill",
                totalBuyIn: 0,
                buyInCount: 0,
                cashOut: nil,
                profitLoss: 0
            ))

            for buyIn in ps.buyIns {
                events.append(BuyInEvent(id: buyIn.id.uuidString, playerName: name, timestamp: buyIn.timestamp,
                                         amount: buyIn.amount, cumulativeTotal: 0, isCashOut: false,
                                         playerId: playerId, recordedBy: nil))
            }
            if let cashOut = ps.cashOut {
                events.append(BuyInEvent(id: RoomReducer.cashOutEventId(for: playerId), playerName: name,
                                         timestamp: ps.cashOutTime ?? session.endedAt ?? Date(),
                                         amount: cashOut, cumulativeTotal: 0, isCashOut: true,
                                         playerId: playerId, recordedBy: nil))
            }
        }

        room.buyInTimeline = events
        RoomReducer.recompute(&room)
        return room
    }
}
