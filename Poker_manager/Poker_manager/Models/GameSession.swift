
import Foundation
import SwiftData

enum GameStatus: String, Codable {
    case active
    case completed
}

@Model
final class GameSession {
    var id: UUID
    var date: Date
    var status: GameStatus
    var notes: String?
    var groupId: String = "local"
    
    var endedAt: Date?
    
    /// Code of the live room this game is shared in, so the host reconnects
    /// to it after the app restarts.
    var roomCode: String?
    
    @Relationship(deleteRule: .cascade)
    var playerSessions: [PlayerSession] = []
    
    init(groupId: String = "local") {
        self.id = UUID()
        self.date = Date()
        self.status = .active
        self.groupId = groupId
    }
    
    var totalPot: Double {
        playerSessions.reduce(0) { sessionSum, session in
            sessionSum + session.buyIns.reduce(0) { buyInSum, buyIn in
                buyInSum + buyIn.amount
            }
        }
    }
    
    /// The pot remaining on the table (totalPot minus cash-outs)
    var remainingPot: Double {
        let cashOuts = playerSessions.reduce(0.0) { $0 + ($1.cashOut ?? 0) }
        return totalPot - cashOuts
    }
    
    var playerCount: Int {
        playerSessions.count
    }
    
    var duration: TimeInterval {
        let end = endedAt ?? Date()
        return end.timeIntervalSince(date)
    }
}
