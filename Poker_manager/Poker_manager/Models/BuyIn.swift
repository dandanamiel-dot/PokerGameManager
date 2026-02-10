
import Foundation
import SwiftData

@Model
final class BuyIn {
    var id: UUID
    var amount: Double
    var timestamp: Date
    
    init(amount: Double) {
        self.id = UUID()
        self.amount = amount
        self.timestamp = Date()
    }
}
