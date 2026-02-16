
import Foundation

// MARK: - Firestore-backed models for multiplayer room sync

struct GameRoom: Codable {
    var roomCode: String
    var hostId: String
    var status: String // "active" or "completed"
    var createdAt: Date
    var gameName: String?
    var totalPot: Double
    var players: [PlayerSnapshot]
    var buyInTimeline: [BuyInEvent]
    var settlement: [SettlementEntry]
    
    init(roomCode: String, hostId: String) {
        self.roomCode = roomCode
        self.hostId = hostId
        self.status = "active"
        self.createdAt = Date()
        self.totalPot = 0
        self.players = []
        self.buyInTimeline = []
        self.settlement = []
    }
}

struct PlayerSnapshot: Codable, Identifiable {
    var id: String // player UUID string
    var name: String
    var avatar: String
    var totalBuyIn: Double
    var buyInCount: Int
    var cashOut: Double?
    var profitLoss: Double
}

struct BuyInEvent: Codable, Identifiable {
    var id: String
    var playerName: String
    var timestamp: Date
    var amount: Double
    var cumulativeTotal: Double
}

struct SettlementEntry: Codable, Identifiable {
    var id: String
    var from: String
    var to: String
    var amount: Double
    
    init(from: String, to: String, amount: Double) {
        self.id = UUID().uuidString
        self.from = from
        self.to = to
        self.amount = amount
    }
}

// MARK: - Conversion from local SwiftData models

extension GameRoom {
    
    /// Build a GameRoom snapshot from a local GameSession
    static func from(session: GameSession, roomCode: String, hostId: String) -> GameRoom {
        var room = GameRoom(roomCode: roomCode, hostId: hostId)
        room.status = session.status == .completed ? "completed" : "active"
        room.createdAt = session.date
        room.totalPot = session.totalPot
        
        // Build player snapshots
        room.players = session.playerSessions.map { ps in
            PlayerSnapshot(
                id: ps.player?.id.uuidString ?? UUID().uuidString,
                name: ps.player?.name ?? "Unknown",
                avatar: ps.player?.avatar ?? "person.crop.circle.fill",
                totalBuyIn: ps.totalBuyIn,
                buyInCount: ps.buyIns.count,
                cashOut: ps.cashOut,
                profitLoss: ps.profitLoss
            )
        }
        
        // Build buy-in timeline
        let allBuyIns = session.playerSessions.flatMap { ps in
            ps.buyIns.map { buyIn in
                (playerName: ps.player?.name ?? "Unknown", buyIn: buyIn)
            }
        }.sorted { $0.buyIn.timestamp < $1.buyIn.timestamp }
        
        var cumulative: Double = 0
        room.buyInTimeline = allBuyIns.map { entry in
            cumulative += entry.buyIn.amount
            return BuyInEvent(
                id: entry.buyIn.id.uuidString,
                playerName: entry.playerName,
                timestamp: entry.buyIn.timestamp,
                amount: entry.buyIn.amount,
                cumulativeTotal: cumulative
            )
        }
        
        return room
    }
}
