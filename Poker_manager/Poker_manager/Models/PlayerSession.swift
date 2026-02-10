
import Foundation
import SwiftData

@Model
final class PlayerSession {
    var id: UUID
    
    @Relationship
    var player: Player?
    
    @Relationship(deleteRule: .cascade)
    var buyIns: [BuyIn] = []
    
    var cashOut: Double? // Nil means still playing or game not ended for this player
    
    // Inverse relationship to GameSession is inferred, but we can't strongly type it 
    // without circular dependency issues in some SwiftData versions, 
    // but usually it's fine. Let's rely on GameSession owning PlayerSession.
    
    init(player: Player) {
        self.id = UUID()
        self.player = player
    }
    
    var totalBuyIn: Double {
        buyIns.reduce(0) { $0 + $1.amount }
    }
    
    var profitLoss: Double {
        guard let cashOut = cashOut else { return -totalBuyIn }
        return cashOut - totalBuyIn
    }
    
    func addBuyIn(amount: Double) {
        let buyIn = BuyIn(amount: amount)
        buyIns.append(buyIn)
    }
}
