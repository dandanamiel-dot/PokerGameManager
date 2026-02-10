
import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var name: String
    var avatar: String // SF Symbol name
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \PlayerSession.player)
    var sessions: [PlayerSession] = []
    
    init(name: String, avatar: String = "person.crop.circle.fill") {
        self.id = UUID()
        self.name = name
        self.avatar = avatar
        self.createdAt = Date()
    }
}
