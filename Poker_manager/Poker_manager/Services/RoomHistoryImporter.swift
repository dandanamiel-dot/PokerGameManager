import Foundation
import SwiftData

/// Saves a finished live game into this phone's history, for co-admins and
/// viewers who didn't host it.
enum RoomHistoryImporter {

    static func hasSaved(roomCode: String, in context: ModelContext) -> Bool {
        let code: String? = roomCode
        let descriptor = FetchDescriptor<GameSession>(predicate: #Predicate { $0.roomCode == code })
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    static func save(_ room: GameRoom, groupId: String, in context: ModelContext) throws {
        guard !hasSaved(roomCode: room.roomCode, in: context) else { return }

        let gId = groupId
        let knownPlayers = (try? context.fetch(FetchDescriptor<Player>(predicate: #Predicate { $0.groupId == gId }))) ?? []

        let session = GameSession(groupId: groupId)
        session.date = room.createdAt
        session.roomCode = room.roomCode
        session.status = room.isActive ? .active : .completed
        session.endedAt = room.endedAt ?? room.lastActivity

        for snapshot in room.players {
            let player: Player
            if let known = knownPlayers.first(where: { $0.id.uuidString == snapshot.id })
                ?? knownPlayers.first(where: { $0.name.caseInsensitiveCompare(snapshot.name) == .orderedSame }) {
                player = known
            } else {
                player = Player(name: snapshot.name, avatar: snapshot.avatar, groupId: groupId)
                context.insert(player)
            }

            let ps = PlayerSession(player: player)
            for event in room.buyInTimeline where event.playerId == snapshot.id && event.isCashOut != true {
                let buyIn = ps.addBuyIn(amount: event.amount)
                buyIn.id = UUID(uuidString: event.id) ?? UUID()
                buyIn.timestamp = event.timestamp
            }
            ps.cashOut = snapshot.cashOut
            if let cashOutEvent = room.buyInTimeline.first(where: { $0.id == RoomReducer.cashOutEventId(for: snapshot.id) }),
               room.endedAt.map({ cashOutEvent.timestamp < $0 }) ?? true {
                ps.cashOutTime = cashOutEvent.timestamp
            }
            if let first = ps.buyIns.map(\.timestamp).min() {
                ps.joinedAt = first
            }
            session.playerSessions.append(ps)
        }

        context.insert(session)
        try context.save()
    }
}
