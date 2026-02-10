
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
    
    var endedAt: Date?
    
    @Relationship(deleteRule: .cascade)
    var playerSessions: [PlayerSession] = []
    
    init() {
        self.id = UUID()
        self.date = Date()
        self.status = .active
    }
    
    var totalPot: Double {
        playerSessions.reduce(0) { sessionSum, session in
            sessionSum + session.buyIns.reduce(0) { buyInSum, buyIn in
                buyInSum + buyIn.amount
            }
        }
    }
    
    var playerCount: Int {
        playerSessions.count
    }
    
    var duration: TimeInterval {
        let end = endedAt ?? Date()
        return end.timeIntervalSince(date)
    }
}
